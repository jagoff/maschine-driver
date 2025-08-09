#!/bin/bash

# Script completo para activar el dispositivo Maschine Mikro
# usando los comandos exactos del proyecto Git

echo "🎹 ========================================="
echo "🎹 ACTIVACIÓN COMPLETA MASCHINE MIKRO"
echo "🎹 ========================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}🔍 Paso 1: Verificando estado del driver...${NC}"

# Verificar si el driver está ejecutándose
DRIVER_PID=$(pgrep -f "maschine_driver")
if [ -n "$DRIVER_PID" ]; then
    echo -e "${GREEN}✅ Driver ejecutándose (PID: $DRIVER_PID)${NC}"
else
    echo -e "${YELLOW}⚠️  Driver no ejecutándose, iniciando...${NC}"
    ./maschine_driver_control.sh start
    sleep 2
    DRIVER_PID=$(pgrep -f "maschine_driver")
fi

echo ""
echo -e "${BLUE}🔍 Paso 2: Enviando comandos de activación completos...${NC}"

# Crear el programa de activación usando los comandos exactos del proyecto
cat > /tmp/complete_activation.cpp << 'EOF'
#include <iostream>
#include <thread>
#include <chrono>
#include <CoreMIDI/CoreMIDI.h>
#include <CoreFoundation/CoreFoundation.h>

void sendSysEx(MIDIPortRef port, MIDIEndpointRef dest, const unsigned char* data, size_t length) {
    MIDIPacketList packetList;
    MIDIPacket *packet = MIDIPacketListInit(&packetList);
    MIDIPacketListAdd(&packetList, sizeof(packetList), packet, 0, length, data);
    MIDISend(port, dest, &packetList);
    std::cout << "📤 SysEx: ";
    for (size_t i = 0; i < length; i++) {
        printf("%02X ", data[i]);
    }
    std::cout << std::endl;
}

void sendMIDI(MIDIPortRef port, MIDIEndpointRef dest, unsigned char status, unsigned char data1, unsigned char data2) {
    unsigned char midiData[] = {status, data1, data2};
    MIDIPacketList packetList;
    MIDIPacket *packet = MIDIPacketListInit(&packetList);
    MIDIPacketListAdd(&packetList, sizeof(packetList), packet, 0, 3, midiData);
    MIDISend(port, dest, &packetList);
    printf("📤 MIDI: %02X %02X %02X\n", status, data1, data2);
}

int main() {
    std::cout << "🎹 Activación completa usando comandos del proyecto..." << std::endl;
    
    // Crear cliente MIDI
    MIDIClientRef client;
    MIDIClientCreate(CFSTR("Complete Activation"), NULL, NULL, &client);
    
    // Crear puerto de salida
    MIDIPortRef outputPort;
    MIDIOutputPortCreate(client, CFSTR("Maschine Output"), &outputPort);
    
    // Encontrar Maschine Mikro Output
    ItemCount numDestinations = MIDIGetNumberOfDestinations();
    MIDIEndpointRef maschineOutput = 0;
    
    for (ItemCount i = 0; i < numDestinations; i++) {
        MIDIEndpointRef dest = MIDIGetDestination(i);
        CFStringRef name;
        MIDIObjectGetStringProperty(dest, kMIDIPropertyName, &name);
        
        if (name) {
            char nameStr[256];
            CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
            CFRelease(name);
            
            if (strstr(nameStr, "Maschine Mikro Output") != NULL) {
                maschineOutput = dest;
                std::cout << "✅ Encontrado: " << nameStr << std::endl;
                break;
            }
        }
    }
    
    if (maschineOutput == 0) {
        std::cout << "❌ No se encontró Maschine Mikro Output" << std::endl;
        return 1;
    }
    
    std::cout << "🚀 Iniciando secuencia de activación completa..." << std::endl;
    
    // SECUENCIA 1: Reset completo (basado en test_maschine_wake.cpp)
    std::cout << "\n📤 Secuencia 1: Reset completo" << std::endl;
    
    // All Controllers Off
    sendMIDI(outputPort, maschineOutput, 0xB0, 121, 0);
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // All Notes Off
    sendMIDI(outputPort, maschineOutput, 0xB0, 123, 0);
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // SysEx Reset
    unsigned char resetSysEx[] = {0xF0, 0x7E, 0x00, 0x09, 0x01, 0xF7};
    sendSysEx(outputPort, maschineOutput, resetSysEx, sizeof(resetSysEx));
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    
    // SECUENCIA 2: Handshake específico de Maschine (basado en test_maschine_wake.cpp)
    std::cout << "\n📤 Secuencia 2: Handshake Maschine" << std::endl;
    
    // SysEx Handshake específico de Maschine
    unsigned char handshake[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x7E, 0x00, 0x00, 0xF7};
    sendSysEx(outputPort, maschineOutput, handshake, sizeof(handshake));
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    
    // Identity Request
    unsigned char identity[] = {0xF0, 0x7E, 0x00, 0x06, 0x01, 0xF7};
    sendSysEx(outputPort, maschineOutput, identity, sizeof(identity));
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    
    // SECUENCIA 3: Activación de inputs (basado en test_activate_inputs.cpp)
    std::cout << "\n📤 Secuencia 3: Activando inputs físicos" << std::endl;
    
    // Activar inputs Maschine
    unsigned char activateInputs[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x01, 0x01, 0xF7};
    sendSysEx(outputPort, maschineOutput, activateInputs, sizeof(activateInputs));
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    
    // SECUENCIA 4: Modo normal Maschine (basado en test_activate_inputs.cpp)
    std::cout << "\n📤 Secuencia 4: Activando modo normal Maschine" << std::endl;
    
    // Modo normal Maschine
    unsigned char normalMode[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x02, 0x00, 0xF7};
    sendSysEx(outputPort, maschineOutput, normalMode, sizeof(normalMode));
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    
    // SECUENCIA 5: Comandos adicionales (basado en test_maschine_wake.cpp)
    std::cout << "\n📤 Secuencia 5: Comandos adicionales" << std::endl;
    
    // Program Change
    sendMIDI(outputPort, maschineOutput, 0xC0, 0, 0);
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // Bank Select
    sendMIDI(outputPort, maschineOutput, 0xB0, 0, 0);
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // Pitch Bend Center
    sendMIDI(outputPort, maschineOutput, 0xE0, 0x00, 0x40);
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // SECUENCIA 6: Test de LEDs (basado en test_maschine_init.cpp)
    std::cout << "\n📤 Secuencia 6: Test de LEDs" << std::endl;
    
    // Test LED - Pad 0 Rojo
    unsigned char testLED[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x00, 0x00, 0x01, 0x7F, 0xF7};
    sendSysEx(outputPort, maschineOutput, testLED, sizeof(testLED));
    std::this_thread::sleep_for(std::chrono::milliseconds(2000));
    
    // Apagar LED - Pad 0
    unsigned char offLED[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF7};
    sendSysEx(outputPort, maschineOutput, offLED, sizeof(offLED));
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // SECUENCIA 7: Comando final de activación
    std::cout << "\n📤 Secuencia 7: Comando final de activación" << std::endl;
    
    // Comando específico para activar modo MIDI (basado en test_maschine_mode_final.cpp)
    unsigned char midiMode[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x02, 0x01, 0xF7};
    sendSysEx(outputPort, maschineOutput, midiMode, sizeof(midiMode));
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    
    // Comando para cambiar display
    unsigned char display[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x03, 0x01, 0xF7};
    sendSysEx(outputPort, maschineOutput, display, sizeof(display));
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // SECUENCIA 8: Simular activación física
    std::cout << "\n📤 Secuencia 8: Simulando activación física" << std::endl;
    
    // Simular presionar diferentes pads para activar
    for (int i = 36; i < 52; i++) {
        sendMIDI(outputPort, maschineOutput, 0x90, i, 0x7F); // Note On
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
        sendMIDI(outputPort, maschineOutput, 0x80, i, 0x00); // Note Off
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }
    
    // Simular presionar botones
    for (int i = 16; i < 24; i++) {
        sendMIDI(outputPort, maschineOutput, 0xB0, i, 0x7F); // Control Change
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
        sendMIDI(outputPort, maschineOutput, 0xB0, i, 0x00); // Control Change Off
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }
    
    std::cout << "\n✅ Secuencia de activación completa enviada" << std::endl;
    std::cout << "💡 El dispositivo debería cambiar de modo ahora" << std::endl;
    
    // Limpiar
    MIDIPortDispose(outputPort);
    MIDIClientDispose(client);
    
    return 0;
}
EOF

# Compilar y ejecutar la activación completa
echo "🔨 Compilando activación completa..."
g++ -framework CoreMIDI -framework CoreFoundation -o /tmp/complete_activation /tmp/complete_activation.cpp

if [ $? -eq 0 ]; then
    echo "✅ Activación completa compilada"
    echo "🚀 Ejecutando activación completa..."
    /tmp/complete_activation
else
    echo -e "${RED}❌ Error al compilar activación completa${NC}"
fi

echo ""
echo -e "${BLUE}🔍 Paso 3: Verificando respuesta...${NC}"

# Esperar y verificar logs
sleep 5
echo "📄 Actividad reciente en logs:"
tail -15 /var/log/maschine_driver.log 2>/dev/null || echo "   No hay logs disponibles"

echo ""
echo -e "${BLUE}🔍 Paso 4: Estado final...${NC}"

echo "🎯 El dispositivo debería haber cambiado de:"
echo "   'start maschine or press shift+f1 for midi mode'"
echo "   a un modo activo con funcionalidad completa"
echo ""
echo "💡 Si el dispositivo no cambió:"
echo "   1. Presiona SHIFT + F1 en el dispositivo físico"
echo "   2. Desconecta y reconecta el cable USB"
echo "   3. Reinicia el dispositivo completamente"

echo ""
echo -e "${BLUE}🎹 ========================================="
echo "🎹 ACTIVACIÓN COMPLETA FINALIZADA"
echo "🎹 ========================================="

if [ -n "$DRIVER_PID" ]; then
    echo -e "${GREEN}✅ Driver activo y comandos enviados${NC}"
    echo "🎯 Dispositivo debería estar completamente activado"
    echo "💡 Verifica el display del dispositivo"
else
    echo -e "${RED}❌ Driver no está ejecutándose${NC}"
fi

echo "🎹 ========================================="

# Limpiar archivos temporales
rm -f /tmp/complete_activation.cpp /tmp/complete_activation 