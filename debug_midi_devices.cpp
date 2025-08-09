#include <iostream>
#include <thread>
#include <chrono>
#include <CoreMIDI/CoreMIDI.h>
#include <CoreFoundation/CoreFoundation.h>

void listMIDIDevices() {
    std::cout << "=== MIDI DEVICES DEBUG ===" << std::endl;
    
    // List MIDI Sources (Input devices)
    ItemCount numSources = MIDIGetNumberOfSources();
    std::cout << "\n📥 MIDI Sources (Input devices): " << numSources << std::endl;
    
    for (ItemCount i = 0; i < numSources; ++i) {
        MIDIEndpointRef source = MIDIGetSource(i);
        CFStringRef name;
        MIDIObjectGetStringProperty(source, kMIDIPropertyName, &name);
        char nameStr[256];
        CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
        
        // Get device info
        MIDIEntityRef entity;
        MIDIEndpointGetEntity(source, &entity);
        
        CFStringRef manufacturer;
        MIDIObjectGetStringProperty(entity, kMIDIPropertyManufacturer, &manufacturer);
        char manufacturerStr[256];
        CFStringGetCString(manufacturer, manufacturerStr, sizeof(manufacturerStr), kCFStringEncodingUTF8);
        
        std::cout << "  Source " << i << ": " << nameStr << " (Manufacturer: " << manufacturerStr << ")" << std::endl;
        
        CFRelease(name);
        CFRelease(manufacturer);
    }
    
    // List MIDI Destinations (Output devices)
    ItemCount numDestinations = MIDIGetNumberOfDestinations();
    std::cout << "\n📤 MIDI Destinations (Output devices): " << numDestinations << std::endl;
    
    for (ItemCount i = 0; i < numDestinations; ++i) {
        MIDIEndpointRef destination = MIDIGetDestination(i);
        CFStringRef name;
        MIDIObjectGetStringProperty(destination, kMIDIPropertyName, &name);
        char nameStr[256];
        CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
        
        // Get device info
        MIDIEntityRef entity;
        MIDIEndpointGetEntity(destination, &entity);
        
        CFStringRef manufacturer;
        MIDIObjectGetStringProperty(entity, kMIDIPropertyManufacturer, &manufacturer);
        char manufacturerStr[256];
        CFStringGetCString(manufacturer, manufacturerStr, sizeof(manufacturerStr), kCFStringEncodingUTF8);
        
        std::cout << "  Destination " << i << ": " << nameStr << " (Manufacturer: " << manufacturerStr << ")" << std::endl;
        
        CFRelease(name);
        CFRelease(manufacturer);
    }
    
    // List MIDI Devices
    ItemCount numDevices = MIDIGetNumberOfDevices();
    std::cout << "\n🎹 MIDI Devices: " << numDevices << std::endl;
    
    for (ItemCount i = 0; i < numDevices; ++i) {
        MIDIDeviceRef device = MIDIGetDevice(i);
        CFStringRef name;
        MIDIObjectGetStringProperty(device, kMIDIPropertyName, &name);
        char nameStr[256];
        CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
        
        CFStringRef manufacturer;
        MIDIObjectGetStringProperty(device, kMIDIPropertyManufacturer, &manufacturer);
        char manufacturerStr[256];
        CFStringGetCString(manufacturer, manufacturerStr, sizeof(manufacturerStr), kCFStringEncodingUTF8);
        
        std::cout << "  Device " << i << ": " << nameStr << " (Manufacturer: " << manufacturerStr << ")" << std::endl;
        
        CFRelease(name);
        CFRelease(manufacturer);
    }
}

void testMIDIConnection() {
    std::cout << "\n=== MIDI CONNECTION TEST ===" << std::endl;
    
    MIDIClientRef client;
    OSStatus status = MIDIClientCreate(CFSTR("MIDI Debug Client"), NULL, NULL, &client);
    if (status != noErr) {
        std::cout << "❌ Error creating MIDI client: " << status << std::endl;
        return;
    }
    
    MIDIPortRef inputPort;
    status = MIDIInputPortCreate(client, CFSTR("Debug Input"), 
        [](const MIDIPacketList *pktlist, void *readProcRefCon, void *srcConnRefCon) {
            const MIDIPacket* packet = &pktlist->packet[0];
            std::cout << "📥 MIDI Input received: ";
            for (int i = 0; i < packet->length; ++i) {
                printf("%02X ", packet->data[i]);
            }
            std::cout << std::endl;
        }, NULL, &inputPort);
    
    if (status != noErr) {
        std::cout << "❌ Error creating input port: " << status << std::endl;
        MIDIClientDispose(client);
        return;
    }
    
    // Connect to all sources
    ItemCount numSources = MIDIGetNumberOfSources();
    std::cout << "🔗 Connecting to " << numSources << " MIDI sources..." << std::endl;
    
    for (ItemCount i = 0; i < numSources; ++i) {
        MIDIEndpointRef source = MIDIGetSource(i);
        CFStringRef name;
        MIDIObjectGetStringProperty(source, kMIDIPropertyName, &name);
        char nameStr[256];
        CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
        
        status = MIDIPortConnectSource(inputPort, source, NULL);
        if (status == noErr) {
            std::cout << "✅ Connected to: " << nameStr << std::endl;
        } else {
            std::cout << "❌ Failed to connect to: " << nameStr << " (Error: " << status << ")" << std::endl;
        }
        
        CFRelease(name);
    }
    
    std::cout << "\n🎹 MIDI Debug Client running..." << std::endl;
    std::cout << "Press any key on your Maschine Mikro to see MIDI input" << std::endl;
    std::cout << "Press Ctrl+C to exit" << std::endl;
    
    // Keep running for 30 seconds
    for (int i = 0; i < 30; ++i) {
        std::this_thread::sleep_for(std::chrono::seconds(1));
        std::cout << "." << std::flush;
    }
    std::cout << std::endl;
    
    MIDIPortDispose(inputPort);
    MIDIClientDispose(client);
}

int main() {
    std::cout << "🎹 MIDI Devices Debug Tool" << std::endl;
    std::cout << "=========================" << std::endl;
    
    listMIDIDevices();
    testMIDIConnection();
    
    return 0;
} 