#include "MaschineMikroDriver_User.h"
#include <map>
#include <iostream>
#include <iomanip>
#include <sstream>

MaschineMikroDriverUser::MaschineMikroDriverUser() 
    : midiClient(0), midiOutPort(0), midiDestination(0), 
      running(false), deviceConnected(false) {
    
    // Initialize pad to note mapping (C4 to C6)
    for (int i = 0; i < 16; i++) {
        padToNoteMap[i] = 60 + i; // C4 (60) to C6 (75)
    }
    
    // Initialize button to CC mapping
    buttonToCCMap[BUTTON_SHIFT] = 64;           // Sustain pedal
    buttonToCCMap[BUTTON_MUTE] = 65;            // Portamento
    buttonToCCMap[BUTTON_SOLO] = 66;            // Sostenuto
    buttonToCCMap[BUTTON_SELECT] = 67;          // Soft pedal
    buttonToCCMap[BUTTON_NAVIGATE_LEFT] = 68;   // Legato footswitch
    buttonToCCMap[BUTTON_NAVIGATE_RIGHT] = 69;  // Hold 2
    buttonToCCMap[BUTTON_NAVIGATE_UP] = 70;     // Sound controller 1
    buttonToCCMap[BUTTON_NAVIGATE_DOWN] = 71;   // Sound controller 2
    buttonToCCMap[BUTTON_NAVIGATE_ENTER] = 72;  // Sound controller 3
    buttonToCCMap[BUTTON_NAVIGATE_BACK] = 73;   // Sound controller 4
    buttonToCCMap[BUTTON_NAVIGATE_FORWARD] = 74; // Sound controller 5
    buttonToCCMap[BUTTON_NAVIGATE_STOP] = 75;   // Sound controller 6
    buttonToCCMap[BUTTON_NAVIGATE_PLAY] = 76;   // Sound controller 7
    buttonToCCMap[BUTTON_NAVIGATE_RECORD] = 77; // Sound controller 8
    
    // Encoder mappings
    buttonToCCMap[ENCODER_1] = 10; // Pan
    buttonToCCMap[ENCODER_2] = 11; // Expression
    buttonToCCMap[ENCODER_3] = 12; // Effect control 1
    buttonToCCMap[ENCODER_4] = 13; // Effect control 2
}

MaschineMikroDriverUser::~MaschineMikroDriverUser() {
    cleanup();
}

bool MaschineMikroDriverUser::initialize() {
    std::cout << "Initializing Maschine Mikro Driver (User Space)" << std::endl;
    
    if (!initializeMIDI()) {
        std::cerr << "Failed to initialize MIDI" << std::endl;
        return false;
    }
    
    if (!initializeUSB()) {
        std::cerr << "Failed to initialize USB" << std::endl;
        return false;
    }
    
    std::cout << "Driver initialized successfully" << std::endl;
    return true;
}

bool MaschineMikroDriverUser::initializeMIDI() {
    std::cout << "Initializing MIDI..." << std::endl;
    
    OSStatus status = MIDIClientCreate(CFSTR("Maschine Mikro Driver"), nullptr, nullptr, &midiClient);
    if (status != noErr) {
        std::cerr << "Failed to create MIDI client: " << status << std::endl;
        return false;
    }
    
    status = MIDIOutputPortCreate(midiClient, CFSTR("Maschine Mikro Output"), &midiOutPort);
    if (status != noErr) {
        std::cerr << "Failed to create MIDI output port: " << status << std::endl;
        return false;
    }
    
    // Find first available MIDI destination
    ItemCount numDestinations = MIDIGetNumberOfDestinations();
    if (numDestinations > 0) {
        midiDestination = MIDIGetDestination(0);
        std::cout << "MIDI destination found: " << numDestinations << " available" << std::endl;
    } else {
        std::cout << "No MIDI destinations available" << std::endl;
    }
    
    return true;
}

bool MaschineMikroDriverUser::initializeUSB() {
    std::cout << "Initializing USB (simulation)..." << std::endl;
    
    // Simulate USB device detection
    deviceConnected = true;
    usbBuffer.reserve(64);
    
    std::cout << "USB device simulation initialized" << std::endl;
    return true;
}

void MaschineMikroDriverUser::cleanup() {
    std::cout << "Cleaning up driver..." << std::endl;
    
    stopUSBPolling();
    
    if (midiOutPort) {
        MIDIPortDispose(midiOutPort);
        midiOutPort = 0;
    }
    
    if (midiClient) {
        MIDIClientDispose(midiClient);
        midiClient = 0;
    }
    
    deviceConnected = false;
    std::cout << "Cleanup completed" << std::endl;
}

bool MaschineMikroDriverUser::connectDevice() {
    if (deviceConnected) {
        std::cout << "Device already connected" << std::endl;
        return true;
    }
    
    std::cout << "Connecting to Maschine Mikro..." << std::endl;
    deviceConnected = true;
    startUSBPolling();
    
    std::cout << "Device connected successfully" << std::endl;
    return true;
}

bool MaschineMikroDriverUser::disconnectDevice() {
    if (!deviceConnected) {
        std::cout << "Device not connected" << std::endl;
        return true;
    }
    
    std::cout << "Disconnecting from Maschine Mikro..." << std::endl;
    stopUSBPolling();
    deviceConnected = false;
    
    std::cout << "Device disconnected" << std::endl;
    return true;
}

bool MaschineMikroDriverUser::sendMIDINote(uint8_t note, uint8_t velocity, uint8_t channel) {
    if (!midiOutPort || !midiDestination) {
        std::cerr << "MIDI not initialized" << std::endl;
        return false;
    }
    
    MIDIPacketList packetList;
    MIDIPacket* packet = MIDIPacketListInit(&packetList);
    
    uint8_t data[3];
    data[0] = MIDI_NOTE_ON | (channel & 0x0F);
    data[1] = note & 0x7F;
    data[2] = velocity & 0x7F;
    
    packet = MIDIPacketListAdd(&packetList, sizeof(packetList), packet, 0, 3, data);
    if (!packet) {
        std::cerr << "Failed to create MIDI packet" << std::endl;
        return false;
    }
    
    OSStatus status = MIDISend(midiOutPort, midiDestination, &packetList);
    if (status != noErr) {
        std::cerr << "Failed to send MIDI: " << status << std::endl;
        return false;
    }
    
    return true;
}

bool MaschineMikroDriverUser::sendMIDICC(uint8_t controller, uint8_t value, uint8_t channel) {
    if (!midiOutPort || !midiDestination) {
        std::cerr << "MIDI not initialized" << std::endl;
        return false;
    }
    
    MIDIPacketList packetList;
    MIDIPacket* packet = MIDIPacketListInit(&packetList);
    
    uint8_t data[3];
    data[0] = MIDI_CONTROL_CHANGE | (channel & 0x0F);
    data[1] = controller & 0x7F;
    data[2] = value & 0x7F;
    
    packet = MIDIPacketListAdd(&packetList, sizeof(packetList), packet, 0, 3, data);
    if (!packet) {
        std::cerr << "Failed to create MIDI packet" << std::endl;
        return false;
    }
    
    OSStatus status = MIDISend(midiOutPort, midiDestination, &packetList);
    if (status != noErr) {
        std::cerr << "Failed to send MIDI: " << status << std::endl;
        return false;
    }
    
    return true;
}

bool MaschineMikroDriverUser::sendMIDISysex(const std::vector<uint8_t>& data) {
    if (!midiOutPort || !midiDestination) {
        std::cerr << "MIDI not initialized" << std::endl;
        return false;
    }
    
    MIDIPacketList packetList;
    MIDIPacket* packet = MIDIPacketListInit(&packetList);
    
    packet = MIDIPacketListAdd(&packetList, sizeof(packetList), packet, 0, data.size(), data.data());
    if (!packet) {
        std::cerr << "Failed to create MIDI packet" << std::endl;
        return false;
    }
    
    OSStatus status = MIDISend(midiOutPort, midiDestination, &packetList);
    if (status != noErr) {
        std::cerr << "Failed to send MIDI: " << status << std::endl;
        return false;
    }
    
    return true;
}

void MaschineMikroDriverUser::handlePadPress(uint8_t pad, uint8_t velocity) {
    if (padToNoteMap.find(pad) != padToNoteMap.end()) {
        uint8_t note = padToNoteMap[pad];
        std::cout << "Pad " << (int)pad << " pressed (Note " << (int)note << ", Velocity " << (int)velocity << ")" << std::endl;
        sendMIDINote(note, velocity);
    }
}

void MaschineMikroDriverUser::handlePadRelease(uint8_t pad) {
    if (padToNoteMap.find(pad) != padToNoteMap.end()) {
        uint8_t note = padToNoteMap[pad];
        std::cout << "Pad " << (int)pad << " released (Note " << (int)note << ")" << std::endl;
        sendMIDINote(note, 0); // Note off with velocity 0
    }
}

void MaschineMikroDriverUser::handleButtonPress(uint8_t button) {
    if (buttonToCCMap.find(button) != buttonToCCMap.end()) {
        uint8_t cc = buttonToCCMap[button];
        std::cout << "Button " << (int)button << " pressed (CC " << (int)cc << ")" << std::endl;
        sendMIDICC(cc, 127); // Button on
    }
}

void MaschineMikroDriverUser::handleButtonRelease(uint8_t button) {
    if (buttonToCCMap.find(button) != buttonToCCMap.end()) {
        uint8_t cc = buttonToCCMap[button];
        std::cout << "Button " << (int)button << " released (CC " << (int)cc << ")" << std::endl;
        sendMIDICC(cc, 0); // Button off
    }
}

void MaschineMikroDriverUser::handleEncoderTurn(uint8_t encoder, int8_t delta) {
    if (buttonToCCMap.find(encoder) != buttonToCCMap.end()) {
        uint8_t cc = buttonToCCMap[encoder];
        static std::map<uint8_t, uint8_t> encoderValues;
        
        if (encoderValues.find(encoder) == encoderValues.end()) {
            encoderValues[encoder] = 64; // Center position
        }
        
        int newValue = encoderValues[encoder] + delta;
        if (newValue < 0) newValue = 0;
        if (newValue > 127) newValue = 127;
        
        encoderValues[encoder] = newValue;
        std::cout << "Encoder " << (int)encoder << " turned (CC " << (int)cc << " = " << newValue << ")" << std::endl;
        sendMIDICC(cc, newValue);
    }
}

void MaschineMikroDriverUser::startUSBPolling() {
    if (running) {
        std::cout << "USB polling already running" << std::endl;
        return;
    }
    
    running = true;
    usbThread = std::thread(&MaschineMikroDriverUser::usbPollingLoop, this);
    std::cout << "USB polling started" << std::endl;
}

void MaschineMikroDriverUser::stopUSBPolling() {
    if (!running) {
        return;
    }
    
    running = false;
    if (usbThread.joinable()) {
        usbThread.join();
    }
    std::cout << "USB polling stopped" << std::endl;
}

void MaschineMikroDriverUser::usbPollingLoop() {
    std::cout << "USB polling loop started" << std::endl;
    
    while (running && deviceConnected) {
        // Simulate USB data polling
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
        
        // In a real implementation, this would read USB data
        // For now, we just keep the thread alive
    }
    
    std::cout << "USB polling loop ended" << std::endl;
}

void MaschineMikroDriverUser::printDeviceInfo() {
    std::cout << "\n=== Maschine Mikro Device Info ===" << std::endl;
    std::cout << "Vendor ID: 0x" << std::hex << MASCHINE_MIKRO_VID << std::dec << std::endl;
    std::cout << "Product ID: 0x" << std::hex << MASCHINE_MIKRO_PID << std::dec << std::endl;
    std::cout << "DFU Product ID: 0x" << std::hex << MASCHINE_MIKRO_DFU_PID << std::dec << std::endl;
    std::cout << "Device Connected: " << (deviceConnected ? "Yes" : "No") << std::endl;
    std::cout << "USB Polling: " << (running ? "Active" : "Inactive") << std::endl;
}

void MaschineMikroDriverUser::printMIDIInfo() {
    std::cout << "\n=== MIDI Info ===" << std::endl;
    std::cout << "MIDI Client: " << (midiClient ? "Initialized" : "Not initialized") << std::endl;
    std::cout << "MIDI Output Port: " << (midiOutPort ? "Created" : "Not created") << std::endl;
    std::cout << "MIDI Destination: " << (midiDestination ? "Available" : "Not available") << std::endl;
    
    ItemCount numDestinations = MIDIGetNumberOfDestinations();
    std::cout << "Available MIDI Destinations: " << numDestinations << std::endl;
    
    for (ItemCount i = 0; i < numDestinations; i++) {
        MIDIEndpointRef dest = MIDIGetDestination(i);
        CFStringRef name;
        MIDIObjectGetStringProperty(dest, kMIDIPropertyName, &name);
        if (name) {
            char nameStr[256];
            CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
            std::cout << "  " << i << ": " << nameStr << std::endl;
            CFRelease(name);
        }
    }
}

void MaschineMikroDriverUser::testAllPads() {
    std::cout << "\n=== Testing All Pads ===" << std::endl;
    
    for (int i = 0; i < 16; i++) {
        std::cout << "Testing pad " << i << "..." << std::endl;
        handlePadPress(i, 100);
        std::this_thread::sleep_for(std::chrono::milliseconds(200));
        handlePadRelease(i);
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    
    std::cout << "Pad test completed" << std::endl;
}

void MaschineMikroDriverUser::testAllButtons() {
    std::cout << "\n=== Testing All Buttons ===" << std::endl;
    
    std::vector<uint8_t> buttons = {
        BUTTON_SHIFT, BUTTON_MUTE, BUTTON_SOLO, BUTTON_SELECT,
        BUTTON_NAVIGATE_LEFT, BUTTON_NAVIGATE_RIGHT, BUTTON_NAVIGATE_UP, BUTTON_NAVIGATE_DOWN,
        BUTTON_NAVIGATE_ENTER, BUTTON_NAVIGATE_BACK, BUTTON_NAVIGATE_FORWARD,
        BUTTON_NAVIGATE_STOP, BUTTON_NAVIGATE_PLAY, BUTTON_NAVIGATE_RECORD
    };
    
    for (uint8_t button : buttons) {
        std::cout << "Testing button 0x" << std::hex << (int)button << std::dec << "..." << std::endl;
        handleButtonPress(button);
        std::this_thread::sleep_for(std::chrono::milliseconds(200));
        handleButtonRelease(button);
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    
    std::cout << "Button test completed" << std::endl;
}

void MaschineMikroDriverUser::testEncoders() {
    std::cout << "\n=== Testing All Encoders ===" << std::endl;
    
    std::vector<uint8_t> encoders = {ENCODER_1, ENCODER_2, ENCODER_3, ENCODER_4};
    
    for (uint8_t encoder : encoders) {
        std::cout << "Testing encoder 0x" << std::hex << (int)encoder << std::dec << "..." << std::endl;
        
        // Turn clockwise
        for (int i = 0; i < 5; i++) {
            handleEncoderTurn(encoder, 1);
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }
        
        // Turn counter-clockwise
        for (int i = 0; i < 5; i++) {
            handleEncoderTurn(encoder, -1);
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }
    }
    
    std::cout << "Encoder test completed" << std::endl;
}

void MaschineMikroDriverUser::printStatus() {
    std::cout << "\n=== Driver Status ===" << std::endl;
    std::cout << "Driver Running: " << (isRunning() ? "Yes" : "No") << std::endl;
    std::cout << "Device Connected: " << (isDeviceConnected() ? "Yes" : "No") << std::endl;
    std::cout << "USB Polling: " << (running ? "Active" : "Inactive") << std::endl;
    std::cout << "MIDI Client: " << (midiClient ? "Initialized" : "Not initialized") << std::endl;
    std::cout << "MIDI Output Port: " << (midiOutPort ? "Created" : "Not created") << std::endl;
    std::cout << "MIDI Destination: " << (midiDestination ? "Available" : "Not available") << std::endl;
} 