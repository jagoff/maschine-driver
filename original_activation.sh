#!/bin/bash

# Script basado EXACTAMENTE en el proyecto original
# Usando los comandos SysEx que SÍ funcionan

echo "🎹 ========================================="
echo "🎹 ACTIVACIÓN ORIGINAL MASCHINE MIKRO"
echo "🎹 ========================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}🔍 Paso 1: Verificando estado actual...${NC}"

# Verificar si el driver está ejecutándose
DRIVER_PID=$(pgrep -f "maschine_driver")
if [ -n "$DRIVER_PID" ]; then
    echo -e "${GREEN}✅ Driver ejecutándose (PID: $DRIVER_PID)${NC}"
else
    echo -e "${YELLOW}⚠️  Driver no ejecutándose, iniciando...${NC}"
    ./maschine_driver_control.sh start
    sleep 3
fi

echo ""
echo -e "${BLUE}🔍 Paso 2: Verificando dispositivos MIDI...${NC}"

# Verificar fuentes MIDI
echo "🔍 Fuentes MIDI disponibles:"
maschine_driver --list-sources 2>/dev/null

echo ""
echo "🔍 Destinos MIDI disponibles:"
maschine_driver --list-destinations 2>/dev/null

echo ""
echo -e "${BLUE}🔍 Paso 3: Enviando comandos ORIGINALES del proyecto...${NC}"

# Crear programa con comandos EXACTOS del proyecto original
cat > /tmp/original_activation.cpp << 'EOF'
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
    std::cout << "🎹 Activación ORIGINAL basada en el proyecto Git..." << std::endl;
    
    // Crear cliente MIDI
    MIDIClientRef client;
    MIDIClientCreate(CFSTR("Original Activation"), NULL, NULL, &client);
    
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
    
    std::cout << "🚀 Enviando comandos ORIGINALES del proyecto..." << std::endl;
    
    // COMANDO 1: Reset completo (basado en test_maschine_wake.cpp)
    std::cout << "\n📤 Comando 1: Reset completo" << std::endl;
    sendMIDI(outputPort, maschineOutput, 0xB0, 121, 0); // All Controllers Off
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    sendMIDI(outputPort, maschineOutput, 0xB0, 123, 0); // All Notes Off
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // COMANDO 2: SysEx Reset (basado en test_maschine_wake.cpp)
    std::cout << "\n📤 Comando 2: SysEx Reset" << std::endl;
    unsigned char resetSysEx[] = {0xF0, 0x7E, 0x00, 0x09, 0x01, 0xF7};
    sendSysEx(outputPort, maschineOutput, resetSysEx, sizeof(resetSysEx));
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    
    // COMANDO 3: Handshake ORIGINAL (basado en test_maschine_init.cpp)
    std::cout << "\n📤 Comando 3: Handshake ORIGINAL" << std::endl;
    unsigned char handshake[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x7E, 0x00, 0x00, 0xF7};
    sendSysEx(outputPort, maschineOutput, handshake, sizeof(handshake));
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    
    // COMANDO 4: Identity Request (basado en test_maschine_wake.cpp)
    std::cout << "\n📤 Comando 4: Identity Request" << std::endl;
    unsigned char identity[] = {0xF0, 0x7E, 0x00, 0x06, 0x01, 0xF7};
    sendSysEx(outputPort, maschineOutput, identity, sizeof(identity));
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    
    // COMANDO 5: Activar inputs ORIGINAL (basado en test_activate_inputs.cpp)
    std::cout << "\n📤 Comando 5: Activar inputs ORIGINAL" << std::endl;
    unsigned char activateInputs[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x01, 0x01, 0xF7};
    sendSysEx(outputPort, maschineOutput, activateInputs, sizeof(activateInputs));
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    
    // COMANDO 6: Modo normal ORIGINAL (basado en test_activate_inputs.cpp)
    std::cout << "\n📤 Comando 6: Modo normal ORIGINAL" << std::endl;
    unsigned char normalMode[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x02, 0x00, 0xF7};
    sendSysEx(outputPort, maschineOutput, normalMode, sizeof(normalMode));
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    
    // COMANDO 7: Program Change (basado en test_maschine_wake.cpp)
    std::cout << "\n📤 Comando 7: Program Change" << std::endl;
    sendMIDI(outputPort, maschineOutput, 0xC0, 0, 0);
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // COMANDO 8: Bank Select (basado en test_maschine_wake.cpp)
    std::cout << "\n📤 Comando 8: Bank Select" << std::endl;
    sendMIDI(outputPort, maschineOutput, 0xB0, 0, 0);
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // COMANDO 9: Pitch Bend Center (basado en test_maschine_wake.cpp)
    std::cout << "\n📤 Comando 9: Pitch Bend Center" << std::endl;
    sendMIDI(outputPort, maschineOutput, 0xE0, 0x00, 0x40);
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // COMANDO 10: Test LED ORIGINAL (basado en test_maschine_init.cpp)
    std::cout << "\n📤 Comando 10: Test LED ORIGINAL" << std::endl;
    unsigned char testLED[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x00, 0x00, 0x01, 0x7F, 0xF7};
    sendSysEx(outputPort, maschineOutput, testLED, sizeof(testLED));
    std::this_thread::sleep_for(std::chrono::milliseconds(2000));
    
    // COMANDO 11: Apagar LED ORIGINAL (basado en test_maschine_init.cpp)
    std::cout << "\n📤 Comando 11: Apagar LED ORIGINAL" << std::endl;
    unsigned char offLED[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF7};
    sendSysEx(outputPort, maschineOutput, offLED, sizeof(offLED));
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // COMANDO 12: Test Note (basado en test_maschine_wake.cpp)
    std::cout << "\n📤 Comando 12: Test Note" << std::endl;
    sendMIDI(outputPort, maschineOutput, 0x90, 36, 1); // Note On, Pad 0, velocity 1
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    sendMIDI(outputPort, maschineOutput, 0x80, 36, 0); // Note Off
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    std::cout << "\n✅ Comandos ORIGINALES completados" << std::endl;
    std::cout << "💡 El dispositivo debería estar completamente activo ahora" << std::endl;
    
    // Limpiar
    MIDIPortDispose(outputPort);
    MIDIClientDispose(client);
    
    return 0;
}
EOF

# Compilar y ejecutar
echo "🔨 Compilando activación original..."
g++ -framework CoreMIDI -framework CoreFoundation -o /tmp/original_activation /tmp/original_activation.cpp

if [ $? -eq 0 ]; then
    echo "✅ Activación original compilada"
    echo "🚀 Ejecutando activación original..."
    /tmp/original_activation
else
    echo -e "${RED}❌ Error al compilar activación original${NC}"
fi

echo ""
echo -e "${BLUE}🔍 Paso 4: Verificando resultado...${NC}"

# Esperar y verificar
sleep 3
echo "📄 Actividad reciente en logs:"
tail -10 /var/log/maschine_driver.log 2>/dev/null || echo "   No hay logs disponibles"

echo ""
echo -e "${BLUE}🔍 Paso 5: Probando conexión...${NC}"

# Probar conexión
maschine_driver --test-connection 2>/dev/null

echo ""
echo -e "${BLUE}🔍 Paso 6: Verificando fuentes MIDI...${NC}"

# Verificar si ahora aparece Maschine Mikro Input
echo "🔍 Verificando fuentes MIDI después de activación:"
maschine_driver --list-sources 2>/dev/null

echo ""
echo -e "${BLUE}🎹 ========================================="
echo "🎹 ACTIVACIÓN ORIGINAL COMPLETADA"
echo "🎹 ========================================="

echo "🎯 RESULTADO:"
if maschine_driver --list-sources 2>/dev/null | grep -q "Maschine Mikro Input"; then
    echo -e "${GREEN}✅ ¡Maschine Mikro Input detectada!${NC}"
    echo -e "${GREEN}✅ Activación ORIGINAL exitosa${NC}"
    echo ""
    echo "💡 El dispositivo está completamente funcional:"
    echo "   maschine_driver --debug"
    echo "   maschine_driver --maschine-mode"
else
    echo -e "${YELLOW}⚠️  Maschine Mikro Input aún no detectada${NC}"
    echo -e "${YELLOW}⚠️  Pero los comandos ORIGINALES fueron enviados${NC}"
    echo ""
    echo "🔧 Próximos pasos:"
    echo "   1. Presiona cualquier pad en el dispositivo"
    echo "   2. Presiona SHIFT + F1 en el dispositivo"
    echo "   3. El LED debería haber parpadeado (test LED)"
fi

echo "🎹 ========================================="

# Limpiar archivos temporales
rm -f /tmp/original_activation.cpp /tmp/original_activation 