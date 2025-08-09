#include <iostream>
#include <chrono>
#include <thread>
#include <iomanip>
#include <sstream>
#include <CoreMIDI/CoreMIDI.h>
#include "MaschineMikroDriver/MaschineMikroDriver_User.h"

class PadMonitor {
private:
    MaschineMikroDriverUser* driver;
    MIDIClientRef midiClient;
    MIDIPortRef midiPort;
    bool running;
    
    // Pad state tracking
    bool padStates[16];
    int padVelocities[16];
    
public:
    PadMonitor() : driver(nullptr), midiClient(0), midiPort(0), running(false) {
        // Initialize pad states
        for (int i = 0; i < 16; i++) {
            padStates[i] = false;
            padVelocities[i] = 0;
        }
    }
    
    ~PadMonitor() {
        stop();
    }
    
    bool initialize() {
        std::cout << "🎹 Initializing Maschine Mikro Pad Monitor..." << std::endl;
        
        // Initialize driver
        driver = new MaschineMikroDriverUser();
        if (!driver->initialize()) {
            std::cerr << "❌ Failed to initialize driver" << std::endl;
            return false;
        }
        
        // Initialize MIDI
        if (!initializeMIDI()) {
            std::cerr << "❌ Failed to initialize MIDI" << std::endl;
            return false;
        }
        
        std::cout << "✅ Pad monitor initialized successfully" << std::endl;
        return true;
    }
    
    bool initializeMIDI() {
        OSStatus status;
        
        // Create MIDI client
        status = MIDIClientCreate(CFSTR("Maschine Mikro Pad Monitor"), nullptr, nullptr, &midiClient);
        if (status != noErr) {
            std::cerr << "Failed to create MIDI client: " << status << std::endl;
            return false;
        }
        
        // Create MIDI input port
        status = MIDIInputPortCreate(midiClient, CFSTR("Pad Monitor Input"), 
                                   midiInputCallback, this, &midiPort);
        if (status != noErr) {
            std::cerr << "Failed to create MIDI input port: " << status << std::endl;
            return false;
        }
        
        // Connect to all MIDI sources
        ItemCount sourceCount = MIDIGetNumberOfSources();
        for (ItemCount i = 0; i < sourceCount; i++) {
            MIDIEndpointRef source = MIDIGetSource(i);
            status = MIDIPortConnectSource(midiPort, source, nullptr);
            if (status == noErr) {
                CFStringRef sourceName;
                MIDIObjectGetStringProperty(source, kMIDIPropertyName, &sourceName);
                char name[256];
                CFStringGetCString(sourceName, name, sizeof(name), kCFStringEncodingUTF8);
                std::cout << "🔗 Connected to MIDI source: " << name << std::endl;
            }
        }
        
        return true;
    }
    
    void start() {
        if (!running) {
            running = true;
            std::cout << "\n🎯 Starting pad monitoring..." << std::endl;
            std::cout << "Press pads on your Maschine Mikro to see signals!" << std::endl;
            std::cout << "Press Ctrl+C to stop monitoring\n" << std::endl;
            
            // Start monitoring loop
            monitorLoop();
        }
    }
    
    void stop() {
        running = false;
        if (driver) {
            delete driver;
            driver = nullptr;
        }
        if (midiClient) {
            MIDIClientDispose(midiClient);
            midiClient = 0;
        }
    }
    
private:
    void monitorLoop() {
        while (running) {
            // Simulate pad input for testing (remove this in production)
            simulatePadInput();
            
            // Check for real pad input
            checkPadInput();
            
            // Display pad grid
            displayPadGrid();
            
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }
    }
    
    void simulatePadInput() {
        // Simulate random pad presses for testing
        static int counter = 0;
        counter++;
        
        if (counter % 50 == 0) {  // Every 5 seconds
            int pad = rand() % 16;
            int velocity = 40 + (rand() % 87);  // 40-127
            triggerPad(pad, velocity);
        }
    }
    
    void checkPadInput() {
        // Check for real pad input from driver
        if (driver) {
            // This would check the actual USB data from the device
            // For now, we'll use the simulation
        }
    }
    
    void triggerPad(int pad, int velocity) {
        if (pad >= 0 && pad < 16) {
            padStates[pad] = true;
            padVelocities[pad] = velocity;
            
            // Send MIDI note
            sendMIDINote(pad, velocity);
            
            // Display pad info
            displayPadInfo(pad, velocity);
        }
    }
    
    void sendMIDINote(int pad, int velocity) {
        if (midiPort) {
            // Create MIDI packet
            MIDIPacketList packetList;
            MIDIPacket* packet = MIDIPacketListInit(&packetList);
            
            // Note On message (0x90 = channel 1 note on)
            Byte noteOn[] = {0x90, (Byte)(36 + pad), (Byte)velocity};
            packet = MIDIPacketListAdd(&packetList, sizeof(packetList), packet, 0, 3, noteOn);
            
            // Send to all destinations
            ItemCount destCount = MIDIGetNumberOfDestinations();
            for (ItemCount i = 0; i < destCount; i++) {
                MIDIEndpointRef dest = MIDIGetDestination(i);
                MIDISend(midiPort, dest, &packetList);
            }
        }
    }
    
    void displayPadInfo(int pad, int velocity) {
        auto now = std::chrono::system_clock::now();
        auto time_t = std::chrono::system_clock::to_time_t(now);
        auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
            now.time_since_epoch()) % 1000;
        
        std::stringstream ss;
        ss << std::put_time(std::localtime(&time_t), "%H:%M:%S");
        ss << "." << std::setfill('0') << std::setw(3) << ms.count();
        
        int row = (pad / 4) + 1;
        int col = (pad % 4) + 1;
        int note = 36 + pad;
        
        std::string intensity;
        if (velocity > 100) intensity = "🔴 HARD";
        else if (velocity > 70) intensity = "🟡 MED";
        else if (velocity > 40) intensity = "🟢 SOFT";
        else intensity = "⚪ LIGHT";
        
        std::cout << "[" << ss.str() << "] 🎯 Pad " << std::setw(2) << pad 
                  << " (R" << row << "C" << col << ") - Note " << note 
                  << " - " << intensity << " (Vel: " << std::setw(3) << velocity << ")" << std::endl;
    }
    
    void displayPadGrid() {
        static int frame = 0;
        frame++;
        
        // Only update grid every 10 frames (1 second)
        if (frame % 10 != 0) return;
        
        std::cout << "\n🎹 Pad Grid Status:" << std::endl;
        std::cout << "┌─────┬─────┬─────┬─────┐" << std::endl;
        
        for (int row = 0; row < 4; row++) {
            std::cout << "│";
            for (int col = 0; col < 4; col++) {
                int pad = row * 4 + col;
                if (padStates[pad]) {
                    std::cout << " 🔴 │";
                    padStates[pad] = false;  // Reset after display
                } else {
                    std::cout << " ⚪ │";
                }
            }
            std::cout << std::endl;
            if (row < 3) std::cout << "├─────┼─────┼─────┼─────┤" << std::endl;
        }
        
        std::cout << "└─────┴─────┴─────┴─────┘" << std::endl;
        std::cout << "🔴 = Active Pad | ⚪ = Inactive Pad" << std::endl;
        std::cout << "Waiting for pad input..." << std::endl;
    }
    
    static void midiInputCallback(const MIDIPacketList* packetList, void* readProcRefCon, void* srcConnRefCon) {
        PadMonitor* monitor = static_cast<PadMonitor*>(readProcRefCon);
        const MIDIPacket* packet = &packetList->packet[0];
        
        for (ItemCount i = 0; i < packetList->numPackets; i++) {
            if (packet->length >= 3) {
                Byte status = packet->data[0];
                Byte note = packet->data[1];
                Byte velocity = packet->data[2];
                
                if ((status & 0xF0) == 0x90 && velocity > 0) {  // Note On
                    int pad = note - 36;  // Convert note to pad number
                    if (pad >= 0 && pad < 16) {
                        monitor->triggerPad(pad, velocity);
                    }
                }
            }
            packet = MIDIPacketNext(packet);
        }
    }
};

int main() {
    std::cout << "🎹 Maschine Mikro Pad Monitor" << std::endl;
    std::cout << "==============================" << std::endl;
    
    PadMonitor monitor;
    
    if (!monitor.initialize()) {
        std::cerr << "❌ Failed to initialize pad monitor" << std::endl;
        return 1;
    }
    
    // Set up signal handler for Ctrl+C
    signal(SIGINT, [](int) {
        std::cout << "\n🛑 Stopping pad monitor..." << std::endl;
        exit(0);
    });
    
    monitor.start();
    
    return 0;
} 