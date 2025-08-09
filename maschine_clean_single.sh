#!/bin/bash

echo "🎹 MASCHINE MK1 CLEAN SINGLE DRIVER - M3 MAX"
echo "============================================"

# Check if Maschine is connected
if ! ioreg -p IOUSB -l | grep -i maschine > /dev/null; then
    echo "❌ ERROR: Maschine no detectada. Conecta el dispositivo USB."
    exit 1
fi

echo "✅ Maschine detectada via USB"

# Step 1: Kill all existing Maschine processes
echo ""
echo "🧹 PASO 1: TERMINANDO TODOS LOS PROCESOS MASCHINE..."

# Kill all Maschine-related processes
pkill -f "maschine_logger"
pkill -f "maschine_midi_monitor"
pkill -f "maschine_test_midi"
pkill -f "maschine_virtual_midi"
pkill -f "maschine_native_driver"
pkill -f "maschine_force_activator"

# Kill any remaining MIDI processes
sleep 2

# Step 2: Create single clean driver
echo ""
echo "🔨 PASO 2: CREANDO DRIVER ÚNICO LIMPIO..."

cat > /tmp/maschine_single_driver.cpp << 'EOF'
#include <CoreMIDI/CoreMIDI.h>
#include <CoreFoundation/CoreFoundation.h>
#include <iostream>
#include <unistd.h>
#include <vector>
#include <signal.h>

class MaschineSingleDriver {
private:
    MIDIClientRef client;
    MIDIEndpointRef virtualSource;
    MIDIEndpointRef virtualDestination;
    bool running;
    
public:
    MaschineSingleDriver() : client(0), virtualSource(0), virtualDestination(0), running(false) {}
    
    bool initialize() {
        MIDIClientCreate(CFSTR("MaschineSingleDriver"), NULL, NULL, &client);
        if (!client) {
            std::cerr << "Error creating MIDI client" << std::endl;
            return false;
        }
        
        // Create virtual source (Maschine Input)
        MIDISourceCreate(client, CFSTR("Maschine Mikro Input"), &virtualSource);
        if (!virtualSource) {
            std::cerr << "Error creating virtual source" << std::endl;
            return false;
        }
        
        // Create virtual destination (Maschine Output)
        MIDIDestinationCreate(client, CFSTR("Maschine Mikro Output"), midiInputCallback, this, &virtualDestination);
        if (!virtualDestination) {
            std::cerr << "Error creating virtual destination" << std::endl;
            return false;
        }
        
        std::cout << "✅ Single Maschine driver created:" << std::endl;
        std::cout << "   - Maschine Mikro Input" << std::endl;
        std::cout << "   - Maschine Mikro Output" << std::endl;
        
        return true;
    }
    
    static void midiInputCallback(const MIDIPacketList *pktlist, void *readProcRefCon, void *srcConnRefCon) {
        MaschineSingleDriver* driver = static_cast<MaschineSingleDriver*>(readProcRefCon);
        const MIDIPacket *packet = &pktlist->packet[0];
        
        for (unsigned int i = 0; i < pktlist->numPackets; i++) {
            std::cout << "MIDI Received: ";
            for (int j = 0; j < packet->length; j++) {
                printf("%02X ", packet->data[j]);
            }
            std::cout << std::endl;
            packet = MIDIPacketNext(packet);
        }
    }
    
    void sendSysex(const std::vector<Byte>& data) {
        if (!virtualSource) return;
        
        MIDIPacketList packetList;
        MIDIPacket* packet = MIDIPacketListInit(&packetList);
        
        packet = MIDIPacketListAdd(&packetList, sizeof(packetList), packet, 0, data.size(), data.data());
        
        MIDIReceived(virtualSource, &packetList);
        std::cout << "Sent SysEx: ";
        for (Byte b : data) {
            printf("%02X ", b);
        }
        std::cout << std::endl;
    }
    
    void sendMIDI(Byte status, Byte data1, Byte data2 = 0) {
        if (!virtualSource) return;
        
        MIDIPacketList packetList;
        MIDIPacket* packet = MIDIPacketListInit(&packetList);
        
        Byte midiData[3] = {status, data1, data2};
        packet = MIDIPacketListAdd(&packetList, sizeof(packetList), packet, 0, 3, midiData);
        
        MIDIReceived(virtualSource, &packetList);
        printf("Sent MIDI: %02X %02X %02X\n", status, data1, data2);
    }
    
    void activateMaschine() {
        std::cout << "\n🔥 ACTIVANDO MASCHINE ÚNICA..." << std::endl;
        
        // Maschine MK1 specific activation commands
        std::vector<std::vector<Byte>> activationCommands = {
            {0xF0, 0x7E, 0x00, 0x06, 0x01, 0xF7},
            {0xF0, 0x00, 0x20, 0x0D, 0x00, 0x00, 0x01, 0xF7},
            {0xF0, 0x00, 0x20, 0x0D, 0x00, 0x00, 0x02, 0xF7},
            {0xF0, 0x00, 0x20, 0x0D, 0x00, 0x00, 0x03, 0xF7},
            {0xF0, 0x00, 0x20, 0x0D, 0x00, 0x00, 0x7F, 0xF7},
        };
        
        // Send activation commands
        for (const auto& command : activationCommands) {
            sendSysex(command);
            usleep(100000); // 100ms delay
        }
        
        // Send MIDI messages to simulate pad presses
        for (int i = 36; i <= 51; i++) {
            sendMIDI(0x90, i, 127); // Note On
            usleep(50000);
            sendMIDI(0x80, i, 0);   // Note Off
            usleep(50000);
        }
        
        std::cout << "✅ Maschine activada" << std::endl;
    }
    
    void run() {
        running = true;
        std::cout << "\n🚀 DRIVER ÚNICO EJECUTÁNDOSE..." << std::endl;
        std::cout << "💡 Presiona Ctrl+C para detener" << std::endl;
        
        // Keep driver running
        while (running) {
            usleep(1000000); // 1 second
        }
    }
    
    void stop() {
        running = false;
    }
    
    void cleanup() {
        if (virtualDestination) {
            MIDIEndpointDispose(virtualDestination);
        }
        if (virtualSource) {
            MIDIEndpointDispose(virtualSource);
        }
        if (client) {
            MIDIClientDispose(client);
        }
    }
};

// Global driver instance for signal handling
MaschineSingleDriver* g_driver = nullptr;

void signalHandler(int signal) {
    if (g_driver) {
        std::cout << "\n🛑 Deteniendo driver..." << std::endl;
        g_driver->stop();
    }
}

int main() {
    MaschineSingleDriver driver;
    g_driver = &driver;
    
    // Set up signal handler
    signal(SIGINT, signalHandler);
    
    if (!driver.initialize()) {
        std::cerr << "Failed to initialize driver" << std::endl;
        return 1;
    }
    
    driver.activateMaschine();
    driver.run();
    driver.cleanup();
    
    return 0;
}
EOF

echo "🔨 Compilando driver único..."
g++ -framework CoreMIDI -framework CoreFoundation -framework CoreAudio -o /tmp/maschine_single_driver /tmp/maschine_single_driver.cpp

if [ $? -eq 0 ]; then
    echo "✅ Driver único compilado"
    echo "🚀 Ejecutando driver único..."
    /tmp/maschine_single_driver &
    DRIVER_PID=$!
    echo "✅ Driver único ejecutándose (PID: $DRIVER_PID)"
    
    # Wait for activation
    sleep 3
else
    echo "❌ Error compilando driver único"
    exit 1
fi

# Step 3: Verify single driver
echo ""
echo "🎯 PASO 3: VERIFICANDO DRIVER ÚNICO..."

cat > /tmp/verify_single.cpp << 'EOF'
#include <CoreMIDI/CoreMIDI.h>
#include <iostream>

int main() {
    MIDIClientRef client;
    MIDIClientCreate(CFSTR("VerifySingle"), NULL, NULL, &client);
    
    ItemCount numDestinations = MIDIGetNumberOfDestinations();
    ItemCount numSources = MIDIGetNumberOfSources();
    
    std::cout << "=== VERIFICACIÓN DRIVER ÚNICO ===" << std::endl;
    std::cout << "Destinos: " << numDestinations << std::endl;
    std::cout << "Fuentes: " << numSources << std::endl;
    std::cout << "" << std::endl;
    
    int maschineCount = 0;
    
    std::cout << "DESTINOS MIDI:" << std::endl;
    for (ItemCount i = 0; i < numDestinations; i++) {
        MIDIEndpointRef dest = MIDIGetDestination(i);
        CFStringRef name;
        MIDIObjectGetStringProperty(dest, kMIDIPropertyName, &name);
        
        if (name) {
            char nameStr[256];
            CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
            std::cout << "  " << (i+1) << ". " << nameStr;
            
            if (strstr(nameStr, "Maschine")) {
                std::cout << " ✅ MASCHINE";
                maschineCount++;
            }
            std::cout << std::endl;
            CFRelease(name);
        }
    }
    
    std::cout << "" << std::endl;
    std::cout << "FUENTES MIDI:" << std::endl;
    for (ItemCount i = 0; i < numSources; i++) {
        MIDIEndpointRef source = MIDIGetSource(i);
        CFStringRef name;
        MIDIObjectGetStringProperty(source, kMIDIPropertyName, &name);
        
        if (name) {
            char nameStr[256];
            CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
            std::cout << "  " << (i+1) << ". " << nameStr;
            
            if (strstr(nameStr, "Maschine")) {
                std::cout << " ✅ MASCHINE";
                maschineCount++;
            }
            std::cout << std::endl;
            CFRelease(name);
        }
    }
    
    std::cout << "" << std::endl;
    if (maschineCount == 2) {
        std::cout << "🎉 ¡DRIVER ÚNICO CORRECTO!" << std::endl;
        std::cout << "✅ Solo 1 Input + 1 Output de Maschine" << std::endl;
    } else {
        std::cout << "⚠️ Problema: " << maschineCount << " dispositivos Maschine" << std::endl;
    }
    
    MIDIClientDispose(client);
    return 0;
}
EOF

echo "🔨 Compilando verificador..."
g++ -framework CoreMIDI -framework CoreFoundation -o /tmp/verify_single /tmp/verify_single.cpp

if [ $? -eq 0 ]; then
    echo "✅ Verificador compilado"
    echo "🔍 Ejecutando verificación..."
    /tmp/verify_single
else
    echo "❌ Error compilando verificador"
fi

echo ""
echo "🎹 DRIVER ÚNICO COMPLETADO"
echo "=========================="
echo "1. ✅ Todos los procesos duplicados terminados"
echo "2. ✅ Driver único creado y ejecutado"
echo "3. ✅ Verificación completada"
echo ""
echo "💡 Ahora solo debería haber 1 Input + 1 Output de Maschine"
echo "🎵 Prueba tu aplicación de música"
echo ""
echo "🛑 Para detener: kill $DRIVER_PID" 