#!/bin/bash

echo "🎹 MASCHINE MK1 LOGGER - M3 MAX"
echo "==============================="

# Create log directory
LOG_DIR="/tmp/maschine_logs"
mkdir -p "$LOG_DIR"

# Log file names
USB_LOG="$LOG_DIR/usb_connection.log"
MIDI_LOG="$LOG_DIR/midi_activity.log"
SYSTEM_LOG="$LOG_DIR/system_events.log"
ERROR_LOG="$LOG_DIR/errors.log"
ACTIVITY_LOG="$LOG_DIR/activity.log"

echo "📁 Logs guardados en: $LOG_DIR"
echo ""

# Function to log with timestamp
log_message() {
    local log_file="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$log_file"
}

# Function to monitor USB connections
monitor_usb() {
    echo "🔌 Monitoreando conexiones USB..."
    log_message "$USB_LOG" "Iniciando monitoreo USB"
    
    while true; do
        if ioreg -p IOUSB -l | grep -i maschine > /dev/null; then
            log_message "$USB_LOG" "✅ Maschine detectada via USB"
            
            # Get detailed USB info
            USB_INFO=$(ioreg -p IOUSB -l | grep -A 10 -B 5 -i maschine)
            log_message "$USB_LOG" "USB Info: $USB_INFO"
        else
            log_message "$USB_LOG" "❌ Maschine NO detectada via USB"
        fi
        
        sleep 2
    done
}

# Function to monitor MIDI devices
monitor_midi() {
    echo "🎵 Monitoreando dispositivos MIDI..."
    log_message "$MIDI_LOG" "Iniciando monitoreo MIDI"
    
    while true; do
        # Create temporary MIDI checker
        cat > /tmp/midi_checker.cpp << 'EOF'
#include <CoreMIDI/CoreMIDI.h>
#include <iostream>
#include <fstream>

int main() {
    MIDIClientRef client;
    MIDIClientCreate(CFSTR("MIDIChecker"), NULL, NULL, &client);
    
    ItemCount numDestinations = MIDIGetNumberOfDestinations();
    ItemCount numSources = MIDIGetNumberOfSources();
    
    std::ofstream log("/tmp/maschine_logs/midi_activity.log", std::ios::app);
    log << "[" << __DATE__ << " " << __TIME__ << "] ";
    log << "Destinos: " << numDestinations << ", Fuentes: " << numSources << std::endl;
    
    for (ItemCount i = 0; i < numDestinations; i++) {
        MIDIEndpointRef dest = MIDIGetDestination(i);
        CFStringRef name;
        MIDIObjectGetStringProperty(dest, kMIDIPropertyName, &name);
        
        if (name) {
            char nameStr[256];
            CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
            log << "  Destino " << (i+1) << ": " << nameStr << std::endl;
            CFRelease(name);
        }
    }
    
    for (ItemCount i = 0; i < numSources; i++) {
        MIDIEndpointRef source = MIDIGetSource(i);
        CFStringRef name;
        MIDIObjectGetStringProperty(source, kMIDIPropertyName, &name);
        
        if (name) {
            char nameStr[256];
            CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
            log << "  Fuente " << (i+1) << ": " << nameStr << std::endl;
            CFRelease(name);
        }
    }
    
    MIDIClientDispose(client);
    return 0;
}
EOF
        
        g++ -framework CoreMIDI -framework CoreFoundation -o /tmp/midi_checker /tmp/midi_checker.cpp 2>/dev/null
        if [ $? -eq 0 ]; then
            /tmp/midi_checker
        fi
        
        sleep 3
    done
}

# Function to monitor system events
monitor_system() {
    echo "🖥️ Monitoreando eventos del sistema..."
    log_message "$SYSTEM_LOG" "Iniciando monitoreo del sistema"
    
    while true; do
        # Check for Maschine-related processes
        MASCHINE_PROCS=$(ps aux | grep -i maschine | grep -v grep)
        if [ ! -z "$MASCHINE_PROCS" ]; then
            log_message "$SYSTEM_LOG" "Procesos Maschine: $MASCHINE_PROCS"
        fi
        
        # Check for MIDI-related processes
        MIDI_PROCS=$(ps aux | grep -i midi | grep -v grep)
        if [ ! -z "$MIDI_PROCS" ]; then
            log_message "$SYSTEM_LOG" "Procesos MIDI: $MIDI_PROCS"
        fi
        
        # Check system load
        LOAD=$(uptime | awk -F'load average:' '{print $2}')
        log_message "$SYSTEM_LOG" "Carga del sistema: $LOAD"
        
        sleep 5
    done
}

# Function to create MIDI activity monitor
create_midi_monitor() {
    echo "🎹 Creando monitor de actividad MIDI..."
    
    cat > /tmp/maschine_midi_monitor.cpp << 'EOF'
#include <CoreMIDI/CoreMIDI.h>
#include <CoreFoundation/CoreFoundation.h>
#include <iostream>
#include <fstream>
#include <unistd.h>

class MaschineMIDIMonitor {
private:
    MIDIClientRef client;
    MIDIPortRef inputPort;
    std::ofstream logFile;
    
public:
    MaschineMIDIMonitor() : client(0), inputPort(0) {
        logFile.open("/tmp/maschine_logs/activity.log", std::ios::app);
    }
    
    bool initialize() {
        MIDIClientCreate(CFSTR("MaschineMIDIMonitor"), NULL, NULL, &client);
        if (!client) {
            logFile << "Error creating MIDI client" << std::endl;
            return false;
        }
        
        MIDIInputPortCreate(client, CFSTR("MaschineMonitor"), midiInputCallback, this, &inputPort);
        if (!inputPort) {
            logFile << "Error creating input port" << std::endl;
            return false;
        }
        
        // Connect to all Maschine sources
        ItemCount numSources = MIDIGetNumberOfSources();
        for (ItemCount i = 0; i < numSources; i++) {
            MIDIEndpointRef source = MIDIGetSource(i);
            CFStringRef name;
            MIDIObjectGetStringProperty(source, kMIDIPropertyName, &name);
            
            if (name) {
                char nameStr[256];
                CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
                if (strstr(nameStr, "Maschine") || strstr(nameStr, "NI")) {
                    MIDIPortConnectSource(inputPort, source, NULL);
                    logFile << "Connected to: " << nameStr << std::endl;
                }
                CFRelease(name);
            }
        }
        
        return true;
    }
    
    static void midiInputCallback(const MIDIPacketList *pktlist, void *readProcRefCon, void *srcConnRefCon) {
        MaschineMIDIMonitor* monitor = static_cast<MaschineMIDIMonitor*>(readProcRefCon);
        const MIDIPacket *packet = &pktlist->packet[0];
        
        for (unsigned int i = 0; i < pktlist->numPackets; i++) {
            monitor->logFile << "MIDI Input: ";
            for (int j = 0; j < packet->length; j++) {
                monitor->logFile << std::hex << (int)packet->data[j] << " ";
            }
            monitor->logFile << std::dec << std::endl;
            packet = MIDIPacketNext(packet);
        }
    }
    
    void run() {
        logFile << "MIDI Monitor iniciado" << std::endl;
        
        // Keep running
        while (true) {
            usleep(1000000); // 1 second
        }
    }
    
    void cleanup() {
        if (inputPort) {
            MIDIPortDispose(inputPort);
        }
        if (client) {
            MIDIClientDispose(client);
        }
        logFile.close();
    }
};

int main() {
    MaschineMIDIMonitor monitor;
    
    if (!monitor.initialize()) {
        return 1;
    }
    
    monitor.run();
    monitor.cleanup();
    return 0;
}
EOF
    
    g++ -framework CoreMIDI -framework CoreFoundation -framework CoreAudio -o /tmp/maschine_midi_monitor /tmp/maschine_midi_monitor.cpp
    
    if [ $? -eq 0 ]; then
        echo "✅ Monitor MIDI compilado"
        /tmp/maschine_midi_monitor &
        MONITOR_PID=$!
        echo "✅ Monitor MIDI ejecutándose (PID: $MONITOR_PID)"
        log_message "$ACTIVITY_LOG" "Monitor MIDI iniciado (PID: $MONITOR_PID)"
    else
        echo "❌ Error compilando monitor MIDI"
        log_message "$ERROR_LOG" "Error compilando monitor MIDI"
    fi
}

# Function to create virtual MIDI for testing
create_test_midi() {
    echo "🎵 Creando MIDI virtual para pruebas..."
    
    cat > /tmp/maschine_test_midi.cpp << 'EOF'
#include <CoreMIDI/CoreMIDI.h>
#include <CoreFoundation/CoreFoundation.h>
#include <iostream>
#include <fstream>
#include <unistd.h>

class MaschineTestMIDI {
private:
    MIDIClientRef client;
    MIDIEndpointRef virtualSource;
    MIDIEndpointRef virtualDestination;
    std::ofstream logFile;
    
public:
    MaschineTestMIDI() : client(0), virtualSource(0), virtualDestination(0) {
        logFile.open("/tmp/maschine_logs/activity.log", std::ios::app);
    }
    
    bool createVirtualMIDI() {
        MIDIClientCreate(CFSTR("MaschineTestMIDI"), NULL, NULL, &client);
        if (!client) {
            logFile << "Error creating MIDI client" << std::endl;
            return false;
        }
        
        // Create virtual source (Maschine Input)
        MIDISourceCreate(client, CFSTR("Maschine Mikro Input"), &virtualSource);
        if (!virtualSource) {
            logFile << "Error creating virtual source" << std::endl;
            return false;
        }
        
        // Create virtual destination (Maschine Output)
        MIDIDestinationCreate(client, CFSTR("Maschine Mikro Output"), midiInputCallback, this, &virtualDestination);
        if (!virtualDestination) {
            logFile << "Error creating virtual destination" << std::endl;
            return false;
        }
        
        logFile << "Virtual MIDI devices created successfully" << std::endl;
        return true;
    }
    
    static void midiInputCallback(const MIDIPacketList *pktlist, void *readProcRefCon, void *srcConnRefCon) {
        MaschineTestMIDI* midi = static_cast<MaschineTestMIDI*>(readProcRefCon);
        const MIDIPacket *packet = &pktlist->packet[0];
        
        for (unsigned int i = 0; i < pktlist->numPackets; i++) {
            midi->logFile << "MIDI Received: ";
            for (int j = 0; j < packet->length; j++) {
                midi->logFile << std::hex << (int)packet->data[j] << " ";
            }
            midi->logFile << std::dec << std::endl;
            packet = MIDIPacketNext(packet);
        }
    }
    
    void sendTestMIDI() {
        if (!virtualSource) return;
        
        // Send test MIDI message
        MIDIPacketList packetList;
        MIDIPacket* packet = MIDIPacketListInit(&packetList);
        
        Byte testMessage[3] = {0x90, 0x3C, 0x7F}; // Note On C4
        packet = MIDIPacketListAdd(&packetList, sizeof(packetList), packet, 0, 3, testMessage);
        
        MIDIReceived(virtualSource, &packetList);
        logFile << "Test MIDI sent: 90 3C 7F" << std::endl;
    }
    
    void run() {
        logFile << "Test MIDI iniciado" << std::endl;
        
        // Send test MIDI every 10 seconds
        while (true) {
            sendTestMIDI();
            usleep(10000000); // 10 seconds
        }
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
        logFile.close();
    }
};

int main() {
    MaschineTestMIDI midi;
    
    if (!midi.createVirtualMIDI()) {
        return 1;
    }
    
    midi.run();
    midi.cleanup();
    return 0;
}
EOF
    
    g++ -framework CoreMIDI -framework CoreFoundation -framework CoreAudio -o /tmp/maschine_test_midi /tmp/maschine_test_midi.cpp
    
    if [ $? -eq 0 ]; then
        echo "✅ Test MIDI compilado"
        /tmp/maschine_test_midi &
        TEST_PID=$!
        echo "✅ Test MIDI ejecutándose (PID: $TEST_PID)"
        log_message "$ACTIVITY_LOG" "Test MIDI iniciado (PID: $TEST_PID)"
    else
        echo "❌ Error compilando test MIDI"
        log_message "$ERROR_LOG" "Error compilando test MIDI"
    fi
}

# Start all monitoring processes
echo "🚀 Iniciando monitoreo completo..."

# Start monitoring in background
monitor_usb &
USB_PID=$!

monitor_midi &
MIDI_PID=$!

monitor_system &
SYSTEM_PID=$!

# Create MIDI monitor and test
create_midi_monitor
create_test_midi

echo ""
echo "📊 MONITOREANDO ACTIVAMENTE..."
echo "=============================="
echo "📁 Logs en: $LOG_DIR"
echo "📋 Archivos de log:"
echo "   - usb_connection.log: Conexiones USB"
echo "   - midi_activity.log: Actividad MIDI"
echo "   - system_events.log: Eventos del sistema"
echo "   - activity.log: Actividad MIDI en tiempo real"
echo "   - errors.log: Errores encontrados"
echo ""
echo "🎹 Ahora prueba tu Maschine MK1..."
echo "💡 Los logs se actualizan automáticamente"
echo ""
echo "🛑 Para detener el monitoreo: Ctrl+C"

# Wait for user to stop
trap 'echo ""; echo "🛑 Deteniendo monitoreo..."; kill $USB_PID $MIDI_PID $SYSTEM_PID 2>/dev/null; echo "✅ Monitoreo detenido"; echo "📁 Revisa los logs en: $LOG_DIR"; exit 0' INT

# Keep running
while true; do
    sleep 1
done 