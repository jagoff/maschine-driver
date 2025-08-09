#include <iostream>
#include <CoreMIDI/CoreMIDI.h>
#include <CoreFoundation/CoreFoundation.h>

int main() {
    std::cout << "🎹 MIDI Devices List" << std::endl;
    std::cout << "====================" << std::endl;
    
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
        OSStatus status = MIDIEndpointGetEntity(source, &entity);
        
        CFStringRef manufacturer = NULL;
        if (status == noErr) {
            MIDIObjectGetStringProperty(entity, kMIDIPropertyManufacturer, &manufacturer);
        }
        
        char manufacturerStr[256] = "Unknown";
        if (manufacturer) {
            CFStringGetCString(manufacturer, manufacturerStr, sizeof(manufacturerStr), kCFStringEncodingUTF8);
        }
        
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
        OSStatus status = MIDIEndpointGetEntity(destination, &entity);
        
        CFStringRef manufacturer = NULL;
        if (status == noErr) {
            MIDIObjectGetStringProperty(entity, kMIDIPropertyManufacturer, &manufacturer);
        }
        
        char manufacturerStr[256] = "Unknown";
        if (manufacturer) {
            CFStringGetCString(manufacturer, manufacturerStr, sizeof(manufacturerStr), kCFStringEncodingUTF8);
        }
        
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
    
    return 0;
} 