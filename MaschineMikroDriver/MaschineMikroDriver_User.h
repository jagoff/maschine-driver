#ifndef MASCHINE_MIKRO_DRIVER_USER_H
#define MASCHINE_MIKRO_DRIVER_USER_H

#include <iostream>
#include <string>
#include <vector>
#include <thread>
#include <chrono>
#include <atomic>
#include <map>
#include <CoreMIDI/CoreMIDI.h>
#include <CoreFoundation/CoreFoundation.h>

// MIDI Constants
#define MIDI_NOTE_OFF           0x80
#define MIDI_NOTE_ON            0x90
#define MIDI_CONTROL_CHANGE     0xB0
#define MIDI_PROGRAM_CHANGE     0xC0
#define MIDI_PITCH_BEND         0xE0
#define MIDI_SYSEX_START        0xF0
#define MIDI_SYSEX_END          0xF7

// Maschine Mikro specific constants
#define MASCHINE_MIKRO_VID      0x17CC
#define MASCHINE_MIKRO_PID      0x1110
#define MASCHINE_MIKRO_DFU_PID  0x1112

// USB Endpoints
#define USB_ENDPOINT_IN         0x81
#define USB_ENDPOINT_OUT        0x01
#define USB_ENDPOINT_INTERRUPT  0x83

// Maschine Mikro button mappings
#define BUTTON_GROUP_A          0x00
#define BUTTON_GROUP_B          0x01
#define BUTTON_GROUP_C          0x02
#define BUTTON_GROUP_D          0x03
#define BUTTON_GROUP_E          0x04
#define BUTTON_GROUP_F          0x05
#define BUTTON_GROUP_G          0x06
#define BUTTON_GROUP_H          0x07

#define BUTTON_ROW_1            0x00
#define BUTTON_ROW_2            0x01
#define BUTTON_ROW_3            0x02
#define BUTTON_ROW_4            0x03

// Pad mappings
#define PAD_1_1                 (BUTTON_GROUP_A << 4) | BUTTON_ROW_1
#define PAD_1_2                 (BUTTON_GROUP_A << 4) | BUTTON_ROW_2
#define PAD_1_3                 (BUTTON_GROUP_A << 4) | BUTTON_ROW_3
#define PAD_1_4                 (BUTTON_GROUP_A << 4) | BUTTON_ROW_4
#define PAD_2_1                 (BUTTON_GROUP_B << 4) | BUTTON_ROW_1
#define PAD_2_2                 (BUTTON_GROUP_B << 4) | BUTTON_ROW_2
#define PAD_2_3                 (BUTTON_GROUP_B << 4) | BUTTON_ROW_3
#define PAD_2_4                 (BUTTON_GROUP_B << 4) | BUTTON_ROW_4
#define PAD_3_1                 (BUTTON_GROUP_C << 4) | BUTTON_ROW_1
#define PAD_3_2                 (BUTTON_GROUP_C << 4) | BUTTON_ROW_2
#define PAD_3_3                 (BUTTON_GROUP_C << 4) | BUTTON_ROW_3
#define PAD_3_4                 (BUTTON_GROUP_C << 4) | BUTTON_ROW_4
#define PAD_4_1                 (BUTTON_GROUP_D << 4) | BUTTON_ROW_1
#define PAD_4_2                 (BUTTON_GROUP_D << 4) | BUTTON_ROW_2
#define PAD_4_3                 (BUTTON_GROUP_D << 4) | BUTTON_ROW_3
#define PAD_4_4                 (BUTTON_GROUP_D << 4) | BUTTON_ROW_4

// Control buttons
#define BUTTON_SHIFT            0x40
#define BUTTON_MUTE            0x41
#define BUTTON_SOLO            0x42
#define BUTTON_SELECT          0x43
#define BUTTON_NAVIGATE_LEFT   0x44
#define BUTTON_NAVIGATE_RIGHT  0x45
#define BUTTON_NAVIGATE_UP     0x46
#define BUTTON_NAVIGATE_DOWN   0x47
#define BUTTON_NAVIGATE_ENTER  0x48
#define BUTTON_NAVIGATE_BACK   0x49
#define BUTTON_NAVIGATE_FORWARD 0x4A
#define BUTTON_NAVIGATE_STOP   0x4B
#define BUTTON_NAVIGATE_PLAY   0x4C
#define BUTTON_NAVIGATE_RECORD 0x4D

// Encoder
#define ENCODER_1              0x50
#define ENCODER_2              0x51
#define ENCODER_3              0x52
#define ENCODER_4              0x53

class MaschineMikroDriverUser {
private:
    MIDIClientRef midiClient;
    MIDIPortRef midiOutPort;
    MIDIEndpointRef midiDestination;
    std::atomic<bool> running;
    std::thread usbThread;
    
    // USB device simulation
    bool deviceConnected;
    std::vector<uint8_t> usbBuffer;
    
    // MIDI mapping
    std::map<uint8_t, uint8_t> padToNoteMap;
    std::map<uint8_t, uint8_t> buttonToCCMap;
    
public:
    MaschineMikroDriverUser();
    ~MaschineMikroDriverUser();
    
    // Initialization
    bool initialize();
    bool initializeMIDI();
    bool initializeUSB();
    void cleanup();
    
    // USB communication simulation
    bool connectDevice();
    bool disconnectDevice();
    bool isDeviceConnected() const { return deviceConnected; }
    
    // MIDI functionality
    bool sendMIDINote(uint8_t note, uint8_t velocity, uint8_t channel = 0);
    bool sendMIDICC(uint8_t controller, uint8_t value, uint8_t channel = 0);
    bool sendMIDISysex(const std::vector<uint8_t>& data);
    
    // Event handling
    void handlePadPress(uint8_t pad, uint8_t velocity);
    void handlePadRelease(uint8_t pad);
    void handleButtonPress(uint8_t button);
    void handleButtonRelease(uint8_t button);
    void handleEncoderTurn(uint8_t encoder, int8_t delta);
    
    // USB polling simulation
    void startUSBPolling();
    void stopUSBPolling();
    void usbPollingLoop();
    
    // Utility functions
    void printDeviceInfo();
    void printMIDIInfo();
    void testAllPads();
    void testAllButtons();
    void testEncoders();
    
    // Status and diagnostics
    bool isRunning() const { return running; }
    void printStatus();
};

#endif // MASCHINE_MIKRO_DRIVER_USER_H 