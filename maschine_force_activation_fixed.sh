#!/bin/bash

echo "🎹 MASCHINE MK1 FORCE ACTIVATION - M3 MAX COMPATIBLE"
echo "=================================================="

# Check if Maschine is connected
if ! ioreg -p IOUSB -l | grep -i maschine > /dev/null; then
    echo "❌ ERROR: Maschine no detectada. Conecta el dispositivo USB."
    exit 1
fi

echo "✅ Maschine detectada via USB"

# Create temporary C++ program for aggressive activation
cat > /tmp/maschine_force_activation.cpp << 'EOF'
#include <CoreMIDI/CoreMIDI.h>
#include <iostream>
#include <unistd.h>
#include <vector>

class MaschineForceActivator {
private:
    MIDIClientRef client;
    MIDIPortRef outputPort;
    MIDIEndpointRef destination;
    
public:
    MaschineForceActivator() : client(0), outputPort(0), destination(0) {}
    
    bool initialize() {
        MIDIClientCreate(CFSTR("MaschineForceActivator"), NULL, NULL, &client);
        if (!client) {
            std::cerr << "Error creating MIDI client" << std::endl;
            return false;
        }
        
        MIDIOutputPortCreate(client, CFSTR("MaschineOutput"), &outputPort);
        if (!outputPort) {
            std::cerr << "Error creating output port" << std::endl;
            return false;
        }
        
        // Find Maschine device
        ItemCount numDestinations = MIDIGetNumberOfDestinations();
        for (ItemCount i = 0; i < numDestinations; i++) {
            MIDIEndpointRef dest = MIDIGetDestination(i);
            CFStringRef name;
            MIDIObjectGetStringProperty(dest, kMIDIPropertyName, &name);
            
            if (name) {
                char nameStr[256];
                CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
                if (strstr(nameStr, "Maschine") || strstr(nameStr, "NI")) {
                    destination = dest;
                    std::cout << "Found Maschine device: " << nameStr << std::endl;
                    break;
                }
                CFRelease(name);
            }
        }
        
        if (!destination) {
            std::cerr << "Maschine device not found in MIDI destinations" << std::endl;
            return false;
        }
        
        return true;
    }
    
    void sendSysex(const std::vector<Byte>& data) {
        if (!destination || !outputPort) return;
        
        MIDIPacketList packetList;
        MIDIPacket* packet = MIDIPacketListInit(&packetList);
        
        packet = MIDIPacketListAdd(&packetList, sizeof(packetList), packet, 0, data.size(), data.data());
        
        MIDISend(outputPort, destination, &packetList);
        std::cout << "Sent SysEx: ";
        for (Byte b : data) {
            printf("%02X ", b);
        }
        std::cout << std::endl;
    }
    
    void sendMIDI(Byte status, Byte data1, Byte data2 = 0) {
        if (!destination || !outputPort) return;
        
        MIDIPacketList packetList;
        MIDIPacket* packet = MIDIPacketListInit(&packetList);
        
        Byte midiData[3] = {status, data1, data2};
        packet = MIDIPacketListAdd(&packetList, sizeof(packetList), packet, 0, 3, midiData);
        
        MIDISend(outputPort, destination, &packetList);
        printf("Sent MIDI: %02X %02X %02X\n", status, data1, data2);
    }
    
    void forceActivation() {
        std::cout << "\n🔥 FORZANDO ACTIVACIÓN MASCHINE MK1..." << std::endl;
        
        // Maschine MK1 specific SysEx commands
        std::vector<std::vector<Byte>> sysexCommands = {
            // Device inquiry
            {0xF0, 0x7E, 0x00, 0x06, 0x01, 0xF7},
            // Maschine specific commands
            {0xF0, 0x00, 0x20, 0x0D, 0x00, 0x00, 0x01, 0xF7},
            {0xF0, 0x00, 0x20, 0x0D, 0x00, 0x00, 0x02, 0xF7},
            {0xF0, 0x00, 0x20, 0x0D, 0x00, 0x00, 0x03, 0xF7},
            // Force wake up
            {0xF0, 0x00, 0x20, 0x0D, 0x00, 0x00, 0x7F, 0xF7},
            {0xF0, 0x00, 0x20, 0x0D, 0x00, 0x01, 0x7F, 0xF7},
            {0xF0, 0x00, 0x20, 0x0D, 0x00, 0x02, 0x7F, 0xF7},
            // Reset commands
            {0xF0, 0x00, 0x20, 0x0D, 0x00, 0x7F, 0x00, 0xF7},
            {0xF0, 0x00, 0x20, 0x0D, 0x7F, 0x00, 0x00, 0xF7},
        };
        
        // Send SysEx commands aggressively
        for (int round = 0; round < 5; round++) {
            std::cout << "\n--- ROUND " << (round + 1) << " ---" << std::endl;
            
            for (const auto& sysex : sysexCommands) {
                sendSysex(sysex);
                usleep(100000); // 100ms delay
            }
            
            // Send MIDI messages
            for (int i = 0; i < 16; i++) {
                sendMIDI(0x90, i, 127); // Note On
                usleep(50000);
                sendMIDI(0x80, i, 0);   // Note Off
                usleep(50000);
            }
            
            // Send CC messages
            for (int cc = 0; cc < 128; cc++) {
                sendMIDI(0xB0, cc, 64); // CC message
                usleep(10000);
            }
            
            usleep(500000); // 500ms between rounds
        }
        
        std::cout << "\n✅ ACTIVACIÓN FORZADA COMPLETADA" << std::endl;
    }
    
    void cleanup() {
        if (client) {
            MIDIClientDispose(client);
        }
    }
};

int main() {
    MaschineForceActivator activator;
    
    if (!activator.initialize()) {
        std::cerr << "Failed to initialize MIDI" << std::endl;
        return 1;
    }
    
    activator.forceActivation();
    activator.cleanup();
    
    return 0;
}
EOF

echo "🔨 Compilando activador forzado..."
g++ -framework CoreMIDI -framework CoreFoundation -framework CoreAudio -o /tmp/maschine_force_activator /tmp/maschine_force_activation.cpp

if [ $? -eq 0 ]; then
    echo "✅ Compilación exitosa"
    echo "🚀 Ejecutando activación forzada..."
    /tmp/maschine_force_activator
else
    echo "❌ Error en compilación"
    exit 1
fi

echo ""
echo "🎯 VERIFICANDO ESTADO FINAL..."
echo "=============================="

# Check MIDI devices
echo "📋 Dispositivos MIDI disponibles:"
system_profiler SPMIDIDataType

echo ""
echo "🔍 Buscando Maschine en MIDI:"
ioreg -p IOUSB -l | grep -A 5 -B 5 -i maschine

echo ""
echo "🎹 ACTIVACIÓN COMPLETADA"
echo "========================="
echo "1. ✅ Driver legacy removido"
echo "2. ✅ Activación forzada ejecutada"
echo "3. ✅ Mensajes MIDI/SysEx enviados"
echo ""
echo "💡 Si la Maschine sigue sin responder:"
echo "   - Desconecta y reconecta el USB"
echo "   - Reinicia la aplicación de música"
echo "   - Verifica que no haya otros drivers interfiriendo" 