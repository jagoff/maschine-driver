//
//  MaschineMikroDriver.cpp
//  MaschineMikroDriver
//
//  Created for Native Instruments Maschine Mikro USB MIDI Controller
//  Based on Windows driver analysis
//

#include "MaschineMikroDriver.h"
#include <IOKit/IOLib.h>
#include <IOKit/IOBufferMemoryDescriptor.h>
#include <IOKit/IOCommandGate.h>
#include <IOKit/usb/IOUSBHostFamily.h>
#include <CoreMIDI/MIDIServices.h>
#include <mach/mach_time.h>

// Define the superclass
#define super IOService

OSDefineMetaClassAndStructors(MaschineMikroDriver, IOService);

// User client meta class
OSDefineMetaClassAndStructors(MaschineMikroUserClient, IOUserClient);

#pragma mark - MaschineMikroDriver Implementation

bool MaschineMikroDriver::init(OSDictionary* dictionary)
{
    if (!super::init(dictionary)) {
        return false;
    }
    
    // Initialize member variables
    fDevice = NULL;
    fInterface = NULL;
    fInPipe = NULL;
    fOutPipe = NULL;
    fMIDIClient = NULL;
    fMIDIInputPort = NULL;
    fMIDIOutputPort = NULL;
    fMIDIInputEndpoint = NULL;
    fMIDIOutputEndpoint = NULL;
    fDeviceOpen = false;
    fMIDIInitialized = false;
    fDeviceID = 0;
    fWorkLoop = NULL;
    fTimer = NULL;
    
    // Clear buffers
    bzero(fInputBuffer, sizeof(fInputBuffer));
    bzero(fOutputBuffer, sizeof(fOutputBuffer));
    
    IOLog("MaschineMikroDriver: Initialized\n");
    return true;
}

void MaschineMikroDriver::free()
{
    IOLog("MaschineMikroDriver: Freeing driver\n");
    super::free();
}

bool MaschineMikroDriver::start(IOService* provider)
{
    if (!super::start(provider)) {
        return false;
    }
    
    IOLog("MaschineMikroDriver: Starting driver\n");
    
    // Get the USB device
    fDevice = OSDynamicCast(IOUSBHostDevice, provider);
    if (!fDevice) {
        IOLog("MaschineMikroDriver: Failed to get USB device\n");
        return false;
    }
    
    // Initialize the device
    if (!initializeDevice()) {
        IOLog("MaschineMikroDriver: Failed to initialize device\n");
        return false;
    }
    
    // Initialize MIDI
    if (!initializeMIDI()) {
        IOLog("MaschineMikroDriver: Failed to initialize MIDI\n");
        return false;
    }
    
    // Create work loop and timer
    fWorkLoop = getWorkLoop();
    if (!fWorkLoop) {
        IOLog("MaschineMikroDriver: Failed to get work loop\n");
        return false;
    }
    
    fTimer = IOTimerEventSource::timerEventSource(this, OSMemberFunctionCast(IOTimerEventSource::Action, this, &MaschineMikroDriver::timerFired));
    if (!fTimer) {
        IOLog("MaschineMikroDriver: Failed to create timer\n");
        return false;
    }
    
    if (fWorkLoop->addEventSource(fTimer) != kIOReturnSuccess) {
        IOLog("MaschineMikroDriver: Failed to add timer to work loop\n");
        return false;
    }
    
    // Start polling timer (1ms interval)
    fTimer->setTimeoutMS(1);
    
    // Register for power management
    registerService();
    
    IOLog("MaschineMikroDriver: Driver started successfully\n");
    return true;
}

void MaschineMikroDriver::stop(IOService* provider)
{
    IOLog("MaschineMikroDriver: Stopping driver\n");
    
    // Stop timer
    if (fTimer) {
        fTimer->cancelTimeout();
        if (fWorkLoop) {
            fWorkLoop->removeEventSource(fTimer);
        }
        fTimer->release();
        fTimer = NULL;
    }
    
    // Cleanup MIDI
    cleanupMIDI();
    
    // Close USB pipes
    if (fInPipe) {
        fInPipe->abort();
        fInPipe->release();
        fInPipe = NULL;
    }
    
    if (fOutPipe) {
        fOutPipe->abort();
        fOutPipe->release();
        fOutPipe = NULL;
    }
    
    // Release interface
    if (fInterface) {
        fInterface->release();
        fInterface = NULL;
    }
    
    super::stop(provider);
}

bool MaschineMikroDriver::willTerminate(IOService* provider, IOOptionBits options)
{
    IOLog("MaschineMikroDriver: Will terminate\n");
    return super::willTerminate(provider, options);
}

IOReturn MaschineMikroDriver::message(UInt32 type, IOService* provider, void* argument)
{
    switch (type) {
        case kIOMessageDeviceWillPowerOff:
        case kIOMessageDeviceWillNotPowerOff:
            IOLog("MaschineMikroDriver: Power management message received\n");
            break;
    }
    
    return super::message(type, provider, argument);
}

#pragma mark - Device Initialization

bool MaschineMikroDriver::initializeDevice()
{
    IOLog("MaschineMikroDriver: Initializing device\n");
    
    // Get the first interface
    OSIterator* iterator = fDevice->getChildIterator(gIOServicePlane);
    if (!iterator) {
        IOLog("MaschineMikroDriver: Failed to get device iterator\n");
        return false;
    }
    
    fInterface = NULL;
    IOService* child;
    while ((child = OSDynamicCast(IOService, iterator->getNextObject()))) {
        fInterface = OSDynamicCast(IOUSBHostInterface, child);
        if (fInterface) {
            break;
        }
    }
    iterator->release();
    
    if (!fInterface) {
        IOLog("MaschineMikroDriver: Failed to find USB interface\n");
        return false;
    }
    
    // Open the interface
    if (fInterface->open(this) != kIOReturnSuccess) {
        IOLog("MaschineMikroDriver: Failed to open interface\n");
        return false;
    }
    
    // Find input and output pipes
    OSArray* pipes = fInterface->getPipes();
    if (!pipes) {
        IOLog("MaschineMikroDriver: Failed to get pipes\n");
        return false;
    }
    
    for (UInt32 i = 0; i < pipes->getCount(); i++) {
        IOUSBHostPipe* pipe = OSDynamicCast(IOUSBHostPipe, pipes->getObject(i));
        if (!pipe) continue;
        
        UInt8 direction = pipe->getDirection();
        UInt8 number = pipe->getEndpointNumber();
        
        if (direction == kUSBIn && number == 1) {
            fInPipe = pipe;
            fInPipe->retain();
            IOLog("MaschineMikroDriver: Found input pipe\n");
        } else if (direction == kUSBOut && number == 2) {
            fOutPipe = pipe;
            fOutPipe->retain();
            IOLog("MaschineMikroDriver: Found output pipe\n");
        }
    }
    
    if (!fInPipe || !fOutPipe) {
        IOLog("MaschineMikroDriver: Failed to find required pipes\n");
        return false;
    }
    
    fDeviceOpen = true;
    IOLog("MaschineMikroDriver: Device initialized successfully\n");
    return true;
}

#pragma mark - MIDI Initialization

bool MaschineMikroDriver::initializeMIDI()
{
    IOLog("MaschineMikroDriver: Initializing MIDI\n");
    
    // Create MIDI client
    OSStatus status = MIDIClientCreate(CFSTR("Maschine Mikro Driver"), NULL, NULL, &fMIDIClient);
    if (status != noErr) {
        IOLog("MaschineMikroDriver: Failed to create MIDI client: %d\n", (int)status);
        return false;
    }
    
    // Create input port
    status = MIDIInputPortCreate(fMIDIClient, CFSTR("Maschine Mikro Input"), NULL, NULL, &fMIDIInputPort);
    if (status != noErr) {
        IOLog("MaschineMikroDriver: Failed to create MIDI input port: %d\n", (int)status);
        return false;
    }
    
    // Create output port
    status = MIDIOutputPortCreate(fMIDIClient, CFSTR("Maschine Mikro Output"), &fMIDIOutputPort);
    if (status != noErr) {
        IOLog("MaschineMikroDriver: Failed to create MIDI output port: %d\n", (int)status);
        return false;
    }
    
    // Create virtual endpoints
    status = MIDISourceCreate(fMIDIClient, CFSTR("Maschine Mikro"), &fMIDIInputEndpoint);
    if (status != noErr) {
        IOLog("MaschineMikroDriver: Failed to create MIDI source: %d\n", (int)status);
        return false;
    }
    
    status = MIDIDestinationCreate(fMIDIClient, CFSTR("Maschine Mikro"), NULL, NULL, &fMIDIOutputEndpoint);
    if (status != noErr) {
        IOLog("MaschineMikroDriver: Failed to create MIDI destination: %d\n", (int)status);
        return false;
    }
    
    fMIDIInitialized = true;
    IOLog("MaschineMikroDriver: MIDI initialized successfully\n");
    return true;
}

void MaschineMikroDriver::cleanupMIDI()
{
    if (fMIDIInputEndpoint) {
        MIDIEndpointDispose(fMIDIInputEndpoint);
        fMIDIInputEndpoint = NULL;
    }
    
    if (fMIDIOutputEndpoint) {
        MIDIEndpointDispose(fMIDIOutputEndpoint);
        fMIDIOutputEndpoint = NULL;
    }
    
    if (fMIDIInputPort) {
        MIDIPortDispose(fMIDIInputPort);
        fMIDIInputPort = NULL;
    }
    
    if (fMIDIOutputPort) {
        MIDIPortDispose(fMIDIOutputPort);
        fMIDIOutputPort = NULL;
    }
    
    if (fMIDIClient) {
        MIDIClientDispose(fMIDIClient);
        fMIDIClient = NULL;
    }
    
    fMIDIInitialized = false;
}

#pragma mark - USB Data Handling

void MaschineMikroDriver::timerFired(OSObject* owner, IOTimerEventSource* sender)
{
    // Start USB read for next data
    startUSBRead();
    
    // Reschedule timer
    fTimer->setTimeoutMS(1);
}

IOReturn MaschineMikroDriver::startUSBRead()
{
    if (!fInPipe || !fDeviceOpen) {
        return kIOReturnNotOpen;
    }
    
    // Create memory descriptor for the read
    IOMemoryDescriptor* memory = IOBufferMemoryDescriptor::withBytes(fInputBuffer, MASCHINE_MIKRO_EP_SIZE, kIODirectionIn);
    if (!memory) {
        return kIOReturnNoMemory;
    }
    
    // Submit the read request
    IOReturn result = fInPipe->io(memory, MASCHINE_MIKRO_EP_SIZE, this, NULL);
    memory->release();
    
    return result;
}

IOReturn MaschineMikroDriver::completeUSBRead(void* data, UInt32 length, IOReturn status)
{
    if (status == kIOReturnSuccess && length > 0) {
        // Process the received data
        processMIDIInput((const UInt8*)data, length);
    }
    
    return kIOReturnSuccess;
}

IOReturn MaschineMikroDriver::sendUSBData(const UInt8* data, UInt32 length)
{
    if (!fOutPipe || !fDeviceOpen) {
        return kIOReturnNotOpen;
    }
    
    // Create memory descriptor for the write
    IOMemoryDescriptor* memory = IOBufferMemoryDescriptor::withBytes((void*)data, length, kIODirectionOut);
    if (!memory) {
        return kIOReturnNoMemory;
    }
    
    // Submit the write request
    IOReturn result = fOutPipe->io(memory, length, NULL, NULL);
    memory->release();
    
    return result;
}

#pragma mark - MIDI Processing

void MaschineMikroDriver::processMIDIInput(const UInt8* data, UInt32 length)
{
    if (!fMIDIInitialized || !data || length == 0) {
        return;
    }
    
    // Parse MIDI messages from USB data
    for (UInt32 i = 0; i < length; i++) {
        UInt8 byte = data[i];
        
        // Check for MIDI status byte
        if (byte & 0x80) {
            UInt8 status = byte & 0xF0;
            UInt8 channel = byte & 0x0F;
            
            // Handle different MIDI message types
            switch (status) {
                case MIDI_NOTE_ON:
                    if (i + 2 < length) {
                        UInt8 note = data[i + 1];
                        UInt8 velocity = data[i + 2];
                        sendMIDIMessage(byte, note, velocity);
                        i += 2;
                    }
                    break;
                    
                case MIDI_NOTE_OFF:
                    if (i + 2 < length) {
                        UInt8 note = data[i + 1];
                        UInt8 velocity = data[i + 2];
                        sendMIDIMessage(byte, note, velocity);
                        i += 2;
                    }
                    break;
                    
                case MIDI_CONTROL_CHANGE:
                    if (i + 2 < length) {
                        UInt8 controller = data[i + 1];
                        UInt8 value = data[i + 2];
                        sendMIDIMessage(byte, controller, value);
                        i += 2;
                    }
                    break;
                    
                case MIDI_PROGRAM_CHANGE:
                    if (i + 1 < length) {
                        UInt8 program = data[i + 1];
                        sendMIDIMessage(byte, program, 0);
                        i += 1;
                    }
                    break;
                    
                case MIDI_PITCH_BEND:
                    if (i + 2 < length) {
                        UInt8 lsb = data[i + 1];
                        UInt8 msb = data[i + 2];
                        UInt16 value = (msb << 7) | lsb;
                        sendMIDIMessage(byte, lsb, msb);
                        i += 2;
                    }
                    break;
            }
        }
    }
}

void MaschineMikroDriver::sendMIDIMessage(UInt8 status, UInt8 data1, UInt8 data2)
{
    if (!fMIDIInitialized || !fMIDIInputEndpoint) {
        return;
    }
    
    // Create MIDI packet list
    MIDIPacketList packetList;
    MIDIPacket* packet = MIDIPacketListInit(&packetList);
    
    UInt8 midiData[3] = { status, data1, data2 };
    UInt32 dataLength = 3;
    
    // Adjust length for 1-byte messages
    if (status == MIDI_PROGRAM_CHANGE || status == MIDI_CHANNEL_PRESSURE) {
        dataLength = 2;
    }
    
    packet = MIDIPacketListAdd(&packetList, sizeof(packetList), packet, mach_absolute_time(), dataLength, midiData);
    if (packet) {
        MIDIReceived(fMIDIInputEndpoint, &packetList);
    }
}

#pragma mark - MIDI Interface Methods

void MaschineMikroDriver::sendMIDINoteOn(UInt8 note, UInt8 velocity, UInt8 channel)
{
    UInt8 status = MIDI_NOTE_ON | (channel & 0x0F);
    UInt8 data[3] = { status, note, velocity };
    sendUSBData(data, 3);
}

void MaschineMikroDriver::sendMIDINoteOff(UInt8 note, UInt8 velocity, UInt8 channel)
{
    UInt8 status = MIDI_NOTE_OFF | (channel & 0x0F);
    UInt8 data[3] = { status, note, velocity };
    sendUSBData(data, 3);
}

void MaschineMikroDriver::sendMIDIControlChange(UInt8 controller, UInt8 value, UInt8 channel)
{
    UInt8 status = MIDI_CONTROL_CHANGE | (channel & 0x0F);
    UInt8 data[3] = { status, controller, value };
    sendUSBData(data, 3);
}

void MaschineMikroDriver::sendMIDIProgramChange(UInt8 program, UInt8 channel)
{
    UInt8 status = MIDI_PROGRAM_CHANGE | (channel & 0x0F);
    UInt8 data[2] = { status, program };
    sendUSBData(data, 2);
}

void MaschineMikroDriver::sendMIDIPitchBend(UInt16 value, UInt8 channel)
{
    UInt8 status = MIDI_PITCH_BEND | (channel & 0x0F);
    UInt8 lsb = value & 0x7F;
    UInt8 msb = (value >> 7) & 0x7F;
    UInt8 data[3] = { status, lsb, msb };
    sendUSBData(data, 3);
}

void MaschineMikroDriver::sendMIDISysex(const UInt8* data, UInt32 length)
{
    if (!data || length == 0) {
        return;
    }
    
    // Create sysex message with start and end bytes
    UInt8* sysexData = new UInt8[length + 2];
    sysexData[0] = MIDI_SYSEX_START;
    memcpy(&sysexData[1], data, length);
    sysexData[length + 1] = MIDI_SYSEX_END;
    
    sendUSBData(sysexData, length + 2);
    delete[] sysexData;
}

#pragma mark - MaschineMikroUserClient Implementation

bool MaschineMikroUserClient::initWithTask(task_t owningTask, void* securityToken, UInt32 type, OSDictionary* properties)
{
    if (!super::initWithTask(owningTask, securityToken, type, properties)) {
        return false;
    }
    
    fDriver = NULL;
    fTask = owningTask;
    fStarted = false;
    
    return true;
}

void MaschineMikroUserClient::free()
{
    super::free();
}

bool MaschineMikroUserClient::start(IOService* provider)
{
    if (!super::start(provider)) {
        return false;
    }
    
    fDriver = OSDynamicCast(MaschineMikroDriver, provider);
    if (!fDriver) {
        return false;
    }
    
    fStarted = true;
    return true;
}

void MaschineMikroUserClient::stop(IOService* provider)
{
    fStarted = false;
    fDriver = NULL;
    super::stop(provider);
}

IOReturn MaschineMikroUserClient::externalMethod(uint32_t selector, IOUserClientMethodArguments* arguments,
                                                IOUserClientMethodDispatch* dispatch, OSObject* target, void* reference)
{
    if (!fStarted || !fDriver) {
        return kIOReturnNotOpen;
    }
    
    switch (selector) {
        case kSendMIDINoteOn:
            if (arguments->scalarInputCount >= 3) {
                fDriver->sendMIDINoteOn((UInt8)arguments->scalarInput[0], 
                                       (UInt8)arguments->scalarInput[1], 
                                       (UInt8)arguments->scalarInput[2]);
                return kIOReturnSuccess;
            }
            break;
            
        case kSendMIDINoteOff:
            if (arguments->scalarInputCount >= 3) {
                fDriver->sendMIDINoteOff((UInt8)arguments->scalarInput[0], 
                                        (UInt8)arguments->scalarInput[1], 
                                        (UInt8)arguments->scalarInput[2]);
                return kIOReturnSuccess;
            }
            break;
            
        case kSendMIDIControlChange:
            if (arguments->scalarInputCount >= 3) {
                fDriver->sendMIDIControlChange((UInt8)arguments->scalarInput[0], 
                                              (UInt8)arguments->scalarInput[1], 
                                              (UInt8)arguments->scalarInput[2]);
                return kIOReturnSuccess;
            }
            break;
            
        case kSendMIDIProgramChange:
            if (arguments->scalarInputCount >= 2) {
                fDriver->sendMIDIProgramChange((UInt8)arguments->scalarInput[0], 
                                              (UInt8)arguments->scalarInput[1]);
                return kIOReturnSuccess;
            }
            break;
            
        case kSendMIDIPitchBend:
            if (arguments->scalarInputCount >= 2) {
                fDriver->sendMIDIPitchBend((UInt16)arguments->scalarInput[0], 
                                          (UInt8)arguments->scalarInput[1]);
                return kIOReturnSuccess;
            }
            break;
            
        case kSendMIDISysex:
            if (arguments->structureInput && arguments->structureInputSize > 0) {
                fDriver->sendMIDISysex((const UInt8*)arguments->structureInput, 
                                      arguments->structureInputSize);
                return kIOReturnSuccess;
            }
            break;
    }
    
    return kIOReturnBadArgument;
}

IOReturn MaschineMikroUserClient::clientMemoryForType(UInt32 type, IOOptionBits* options, IOMemoryDescriptor** memory)
{
    return kIOReturnUnsupported;
}

IOReturn MaschineMikroUserClient::clientClose()
{
    fStarted = false;
    fDriver = NULL;
    return kIOReturnSuccess;
} 