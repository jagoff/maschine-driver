#include "MaschineMikroDriver/MaschineMikroDriver_User.h"
#include <iostream>
#include <thread>
#include <chrono>
#include <signal.h>

std::atomic<bool> running(true);

void signalHandler(int signum) {
    std::cout << "\nReceived signal " << signum << ", shutting down..." << std::endl;
    running = false;
}

void printMenu() {
    std::cout << "\n=== Maschine Mikro Driver Test Menu ===" << std::endl;
    std::cout << "1. Show device info" << std::endl;
    std::cout << "2. Show MIDI info" << std::endl;
    std::cout << "3. Test all pads" << std::endl;
    std::cout << "4. Test all buttons" << std::endl;
    std::cout << "5. Test all encoders" << std::endl;
    std::cout << "6. Test individual pad" << std::endl;
    std::cout << "7. Test individual button" << std::endl;
    std::cout << "8. Test individual encoder" << std::endl;
    std::cout << "9. Send custom MIDI note" << std::endl;
    std::cout << "10. Send custom MIDI CC" << std::endl;
    std::cout << "11. Show driver status" << std::endl;
    std::cout << "12. Run full test suite" << std::endl;
    std::cout << "0. Exit" << std::endl;
    std::cout << "Enter your choice: ";
}

void runFullTestSuite(MaschineMikroDriverUser& driver) {
    std::cout << "\n=== Running Full Test Suite ===" << std::endl;
    
    // Show initial status
    driver.printStatus();
    driver.printDeviceInfo();
    driver.printMIDIInfo();
    
    // Test all components
    std::cout << "\n--- Testing Pads ---" << std::endl;
    driver.testAllPads();
    
    std::cout << "\n--- Testing Buttons ---" << std::endl;
    driver.testAllButtons();
    
    std::cout << "\n--- Testing Encoders ---" << std::endl;
    driver.testEncoders();
    
    // Test custom MIDI
    std::cout << "\n--- Testing Custom MIDI ---" << std::endl;
    std::cout << "Sending C major scale..." << std::endl;
    uint8_t notes[] = {60, 62, 64, 65, 67, 69, 71, 72}; // C major scale
    for (int i = 0; i < 8; i++) {
        driver.sendMIDINote(notes[i], 100);
        std::this_thread::sleep_for(std::chrono::milliseconds(300));
        driver.sendMIDINote(notes[i], 0);
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    
    std::cout << "\n--- Testing MIDI CC ---" << std::endl;
    for (int i = 0; i < 128; i += 10) {
        driver.sendMIDICC(1, i); // Modulation wheel
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    
    std::cout << "\n=== Full Test Suite Completed ===" << std::endl;
}

int main() {
    std::cout << "Maschine Mikro Driver Test Program" << std::endl;
    std::cout << "===================================" << std::endl;
    
    // Set up signal handler for graceful shutdown
    signal(SIGINT, signalHandler);
    signal(SIGTERM, signalHandler);
    
    // Create and initialize driver
    MaschineMikroDriverUser driver;
    
    if (!driver.initialize()) {
        std::cerr << "Failed to initialize driver" << std::endl;
        return 1;
    }
    
    if (!driver.connectDevice()) {
        std::cerr << "Failed to connect to device" << std::endl;
        return 1;
    }
    
    std::cout << "Driver initialized and device connected successfully!" << std::endl;
    
    // Main test loop
    while (running) {
        printMenu();
        
        int choice;
        std::cin >> choice;
        
        switch (choice) {
            case 0:
                running = false;
                break;
                
            case 1:
                driver.printDeviceInfo();
                break;
                
            case 2:
                driver.printMIDIInfo();
                break;
                
            case 3:
                driver.testAllPads();
                break;
                
            case 4:
                driver.testAllButtons();
                break;
                
            case 5:
                driver.testEncoders();
                break;
                
            case 6: {
                std::cout << "Enter pad number (0-15): ";
                int pad;
                std::cin >> pad;
                if (pad >= 0 && pad <= 15) {
                    std::cout << "Testing pad " << pad << "..." << std::endl;
                    driver.handlePadPress(pad, 100);
                    std::this_thread::sleep_for(std::chrono::milliseconds(500));
                    driver.handlePadRelease(pad);
                } else {
                    std::cout << "Invalid pad number" << std::endl;
                }
                break;
            }
                
            case 7: {
                std::cout << "Enter button number (0x40-0x4D for control buttons, 0x50-0x53 for encoders): ";
                int button;
                std::cin >> std::hex >> button >> std::dec;
                std::cout << "Testing button 0x" << std::hex << button << std::dec << "..." << std::endl;
                driver.handleButtonPress(button);
                std::this_thread::sleep_for(std::chrono::milliseconds(500));
                driver.handleButtonRelease(button);
                break;
            }
                
            case 8: {
                std::cout << "Enter encoder number (0x50-0x53): ";
                int encoder;
                std::cin >> std::hex >> encoder >> std::dec;
                std::cout << "Testing encoder 0x" << std::hex << encoder << std::dec << "..." << std::endl;
                for (int i = 0; i < 10; i++) {
                    driver.handleEncoderTurn(encoder, 1);
                    std::this_thread::sleep_for(std::chrono::milliseconds(100));
                }
                for (int i = 0; i < 10; i++) {
                    driver.handleEncoderTurn(encoder, -1);
                    std::this_thread::sleep_for(std::chrono::milliseconds(100));
                }
                break;
            }
                
            case 9: {
                std::cout << "Enter note number (0-127): ";
                int note;
                std::cin >> note;
                std::cout << "Enter velocity (0-127): ";
                int velocity;
                std::cin >> velocity;
                std::cout << "Enter channel (0-15): ";
                int channel;
                std::cin >> channel;
                
                if (note >= 0 && note <= 127 && velocity >= 0 && velocity <= 127 && channel >= 0 && channel <= 15) {
                    std::cout << "Sending note " << note << " with velocity " << velocity << " on channel " << channel << std::endl;
                    driver.sendMIDINote(note, velocity, channel);
                    std::this_thread::sleep_for(std::chrono::milliseconds(500));
                    driver.sendMIDINote(note, 0, channel);
                } else {
                    std::cout << "Invalid parameters" << std::endl;
                }
                break;
            }
                
            case 10: {
                std::cout << "Enter controller number (0-127): ";
                int controller;
                std::cin >> controller;
                std::cout << "Enter value (0-127): ";
                int value;
                std::cin >> value;
                std::cout << "Enter channel (0-15): ";
                int channel;
                std::cin >> channel;
                
                if (controller >= 0 && controller <= 127 && value >= 0 && value <= 127 && channel >= 0 && channel <= 15) {
                    std::cout << "Sending CC " << controller << " with value " << value << " on channel " << channel << std::endl;
                    driver.sendMIDICC(controller, value, channel);
                } else {
                    std::cout << "Invalid parameters" << std::endl;
                }
                break;
            }
                
            case 11:
                driver.printStatus();
                break;
                
            case 12:
                runFullTestSuite(driver);
                break;
                
            default:
                std::cout << "Invalid choice" << std::endl;
                break;
        }
        
        if (running) {
            std::cout << "\nPress Enter to continue...";
            std::cin.ignore();
            std::cin.get();
        }
    }
    
    std::cout << "Shutting down driver..." << std::endl;
    driver.disconnectDevice();
    
    std::cout << "Test program completed successfully!" << std::endl;
    return 0;
} 