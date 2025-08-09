//
//  MaschineMikroDriver.h
//  MaschineMikroDriver
//
//  Created for Native Instruments Maschine Mikro USB MIDI Controller
//  Based on Windows driver analysis
//

#ifndef MaschineMikroDriver_h
#define MaschineMikroDriver_h

#include <IOKit/IOService.h>
#include <IOKit/IOUserClient.h>
#include <IOKit/usb/IOUSBHostDevice.h>
#include <IOKit/usb/IOUSBHostInterface.h>
#include <IOKit/usb/USB.h>
#include <CoreMIDI/MIDIServices.h>
#include <mach/mach_time.h>

// Maschine Mikro USB VID/PID constants
#define MASCHINE_MIKRO_VID        0x17CC
#define MASCHINE_MIKRO_PID        0x1110
#define MASCHINE_MIKRO_DFU_PID    0x1112

// USB Endpoints
#define MASCHINE_MIKRO_EP_IN      0x81
#define MASCHINE_MIKRO_EP_OUT     0x02
#define MASCHINE_MIKRO_EP_SIZE    64

// MIDI Constants
#define MIDI_NOTE_OFF             0x80
#define MIDI_NOTE_ON              0x90
#define MIDI_CONTROL_CHANGE       0xB0
#define MIDI_PROGRAM_CHANGE       0xC0
#define MIDI_CHANNEL_PRESSURE     0xD0
#define MIDI_PITCH_BEND           0xE0
#define MIDI_SYSEX_START          0xF0
#define MIDI_SYSEX_END            0xF7

// Maschine Mikro specific MIDI messages
#define MASCHINE_MIKRO_NOTE_BASE  36  // C2
#define MASCHINE_MIKRO_CC_BASE    0x10
#define MASCHINE_MIKRO_CC_PAD     0x10
#define MASCHINE_MIKRO_CC_KNOB1   0x11
#define MASCHINE_MIKRO_CC_KNOB2   0x12
#define MASCHINE_MIKRO_CC_KNOB3   0x13
#define MASCHINE_MIKRO_CC_KNOB4   0x14
#define MASCHINE_MIKRO_CC_KNOB5   0x15
#define MASCHINE_MIKRO_CC_KNOB6   0x16
#define MASCHINE_MIKRO_CC_KNOB7   0x17
#define MASCHINE_MIKRO_CC_KNOB8   0x18

class MaschineMikroDriver : public IOService
{
    OSDeclareDefaultStructors(MaschineMikroDriver);
    
private:
    IOUSBHostDevice*      fDevice;
    IOUSBHostInterface*   fInterface;
    IOUSBHostPipe*        fInPipe;
    IOUSBHostPipe*        fOutPipe;
    
    // MIDI Client and Ports
    MIDIClientRef         fMIDIClient;
    MIDIPortRef           fMIDIInputPort;
    MIDIPortRef           fMIDIOutputPort;
    MIDIEndpointRef       fMIDIInputEndpoint;
    MIDIEndpointRef       fMIDIOutputEndpoint;
    
    // Device state
    bool                  fDeviceOpen;
    bool                  fMIDIInitialized;
    UInt32                fDeviceID;
    
    // Buffer for USB transfers
    UInt8                 fInputBuffer[MASCHINE_MIKRO_EP_SIZE];
    UInt8                 fOutputBuffer[MASCHINE_MIKRO_EP_SIZE];
    
    // Work loop and timer for polling
    IOWorkLoop*           fWorkLoop;
    IOTimerEventSource*   fTimer;
    
    // Methods
    bool                  initializeDevice();
    bool                  initializeMIDI();
    void                  cleanupMIDI();
    void                  handleUSBData();
    void                  sendMIDIMessage(UInt8 status, UInt8 data1, UInt8 data2);
    void                  processMIDIInput(const UInt8* data, UInt32 length);
    void                  timerFired(OSObject* owner, IOTimerEventSource* sender);
    
    // USB transfer methods
    IOReturn              startUSBRead();
    IOReturn              completeUSBRead(void* data, UInt32 length, IOReturn status);
    IOReturn              sendUSBData(const UInt8* data, UInt32 length);
    
public:
    // IOService overrides
    virtual bool          init(OSDictionary* dictionary = 0);
    virtual void          free();
    virtual bool          start(IOService* provider);
    virtual void          stop(IOService* provider);
    virtual bool          willTerminate(IOService* provider, IOOptionBits options);
    
    // Device control
    virtual IOReturn      message(UInt32 type, IOService* provider, void* argument = 0);
    
    // MIDI interface
    void                  sendMIDINoteOn(UInt8 note, UInt8 velocity, UInt8 channel = 0);
    void                  sendMIDINoteOff(UInt8 note, UInt8 velocity, UInt8 channel = 0);
    void                  sendMIDIControlChange(UInt8 controller, UInt8 value, UInt8 channel = 0);
    void                  sendMIDIProgramChange(UInt8 program, UInt8 channel = 0);
    void                  sendMIDIPitchBend(UInt16 value, UInt8 channel = 0);
    void                  sendMIDISysex(const UInt8* data, UInt32 length);
};

// User client class for user space communication
class MaschineMikroUserClient : public IOUserClient
{
    OSDeclareDefaultStructors(MaschineMikroUserClient);
    
private:
    MaschineMikroDriver*  fDriver;
    task_t                fTask;
    bool                  fStarted;
    
public:
    virtual bool          initWithTask(task_t owningTask, void* securityToken, UInt32 type, OSDictionary* properties);
    virtual void          free();
    virtual bool          start(IOService* provider);
    virtual void          stop(IOService* provider);
    
    virtual IOReturn      externalMethod(uint32_t selector, IOUserClientMethodArguments* arguments,
                                        IOUserClientMethodDispatch* dispatch, OSObject* target, void* reference);
    
    virtual IOReturn      clientMemoryForType(UInt32 type, IOOptionBits* options, IOMemoryDescriptor** memory);
    virtual IOReturn      clientClose();
    
    // External method selectors
    enum {
        kSendMIDINoteOn = 0,
        kSendMIDINoteOff,
        kSendMIDIControlChange,
        kSendMIDIProgramChange,
        kSendMIDIPitchBend,
        kSendMIDISysex,
        kGetDeviceStatus,
        kSetLED,
        kSetDisplay
    };
};

#endif /* MaschineMikroDriver_h */ 