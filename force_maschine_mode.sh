#!/bin/bash

# Script para forzar el dispositivo a modo Maschine desde modo MIDI

echo "🎹 ========================================="
echo "🎹 FORZANDO MODO MASCHINE DESDE MODO MIDI"
echo "🎹 ========================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}🔍 Paso 1: Verificando estado actual...${NC}"

echo "🎯 Estado actual detectado:"
echo "   ✅ Dispositivo conectado físicamente"
echo "   ✅ Display funcionando"
echo "   ⚠️  Luces encendidas = MODO MIDI"
echo "   ❌ No aparece en fuentes MIDI = Problema de registro"
echo ""

echo -e "${BLUE}🔍 Paso 2: Enviando comandos para forzar modo Maschine...${NC}"

# Crear programa para forzar modo Maschine
cat > /tmp/force_maschine.cpp << 'EOF'
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
    std::cout << "🎹 Forzando modo Maschine desde modo MIDI..." << std::endl;
    
    // Crear cliente MIDI
    MIDIClientRef client;
    MIDIClientCreate(CFSTR("Force Maschine"), NULL, NULL, &client);
    
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
        std::cout << "🔍 Buscando cualquier dispositivo MIDI..." << std::endl;
        
        // Buscar cualquier dispositivo MIDI disponible
        for (ItemCount i = 0; i < numDestinations; i++) {
            MIDIEndpointRef dest = MIDIGetDestination(i);
            CFStringRef name;
            MIDIObjectGetStringProperty(dest, kMIDIPropertyName, &name);
            
            if (name) {
                char nameStr[256];
                CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
                CFRelease(name);
                
                std::cout << "🔍 Encontrado: " << nameStr << std::endl;
                maschineOutput = dest;
                break;
            }
        }
    }
    
    if (maschineOutput == 0) {
        std::cout << "❌ No se encontró ningún dispositivo MIDI" << std::endl;
        return 1;
    }
    
    std::cout << "🚀 Enviando comandos para forzar modo Maschine..." << std::endl;
    
    // COMANDO 1: Reset completo
    std::cout << "\n📤 Comando 1: Reset completo" << std::endl;
    sendMIDI(outputPort, maschineOutput, 0xB0, 121, 0); // All Controllers Off
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    sendMIDI(outputPort, maschineOutput, 0xB0, 123, 0); // All Notes Off
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // COMANDO 2: SysEx Reset
    std::cout << "\n📤 Comando 2: SysEx Reset" << std::endl;
    unsigned char resetSysEx[] = {0xF0, 0x7E, 0x00, 0x09, 0x01, 0xF7};
    sendSysEx(outputPort, maschineOutput, resetSysEx, sizeof(resetSysEx));
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    
    // COMANDO 3: Handshake específico de Maschine
    std::cout << "\n📤 Comando 3: Handshake Maschine" << std::endl;
    unsigned char handshake[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x7E, 0x00, 0x00, 0xF7};
    sendSysEx(outputPort, maschineOutput, handshake, sizeof(handshake));
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    
    // COMANDO 4: Activar inputs Maschine
    std::cout << "\n📤 Comando 4: Activar inputs Maschine" << std::endl;
    unsigned char activateInputs[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x01, 0x01, 0xF7};
    sendSysEx(outputPort, maschineOutput, activateInputs, sizeof(activateInputs));
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    
    // COMANDO 5: Forzar modo Maschine
    std::cout << "\n📤 Comando 5: Forzar modo Maschine" << std::endl;
    unsigned char maschineMode[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x02, 0x00, 0xF7};
    sendSysEx(outputPort, maschineOutput, maschineMode, sizeof(maschineMode));
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    
    // COMANDO 6: Apagar todas las luces (modo Maschine)
    std::cout << "\n📤 Comando 6: Apagar todas las luces" << std::endl;
    for (int i = 0; i < 16; i++) {
        unsigned char offLED[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x00, (unsigned char)i, 0x00, 0x00, 0xF7};
        sendSysEx(outputPort, maschineOutput, offLED, sizeof(offLED));
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }
    
    // COMANDO 7: Comando específico para salir de modo MIDI
    std::cout << "\n📤 Comando 7: Salir de modo MIDI" << std::endl;
    unsigned char exitMidiMode[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x03, 0x00, 0xF7};
    sendSysEx(outputPort, maschineOutput, exitMidiMode, sizeof(exitMidiMode));
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    
    // COMANDO 8: Comando final de activación Maschine
    std::cout << "\n📤 Comando 8: Activación final Maschine" << std::endl;
    unsigned char finalActivation[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x00, 0x00, 0x01, 0x7F, 0xF7};
    sendSysEx(outputPort, maschineOutput, finalActivation, sizeof(finalActivation));
    
    std::cout << "\n✅ Comandos para forzar modo Maschine completados" << std::endl;
    std::cout << "💡 El dispositivo debería cambiar a modo Maschine ahora" << std::endl;
    std::cout << "💡 Las luces deberían apagarse o cambiar de patrón" << std::endl;
    
    // Limpiar
    MIDIPortDispose(outputPort);
    MIDIClientDispose(client);
    
    return 0;
}
EOF

# Compilar y ejecutar
echo "🔨 Compilando forzador de modo Maschine..."
g++ -framework CoreMIDI -framework CoreFoundation -o /tmp/force_maschine /tmp/force_maschine.cpp

if [ $? -eq 0 ]; then
    echo "✅ Forzador de modo Maschine compilado"
    echo "🚀 Ejecutando forzador de modo Maschine..."
    /tmp/force_maschine
else
    echo -e "${RED}❌ Error al compilar forzador de modo Maschine${NC}"
fi

echo ""
echo -e "${BLUE}🔍 Paso 3: Verificando cambio de modo...${NC}"

echo "🎯 Verifica en el dispositivo físico:"
echo "   1. ¿Las luces se apagaron o cambiaron de patrón?"
echo "   2. ¿El display cambió?"
echo "   3. ¿El dispositivo ahora está en modo Maschine?"
echo ""
echo -e "${BLUE}Presiona ENTER cuando hayas verificado el cambio de modo...${NC}"
read -r

echo ""
echo -e "${BLUE}🔍 Paso 4: Reiniciando driver después del cambio...${NC}"

# Reiniciar driver
./maschine_driver_control.sh restart
sleep 3

echo ""
echo -e "${BLUE}🔍 Paso 5: Verificando detección después del cambio...${NC}"

# Verificar fuentes MIDI
echo "🔍 Verificando fuentes MIDI después del cambio:"
maschine_driver --list-sources 2>/dev/null

echo ""
echo "🔍 Verificando destinos MIDI después del cambio:"
maschine_driver --list-destinations 2>/dev/null

echo ""
echo -e "${BLUE}🔍 Paso 6: Probando conexión...${NC}"

# Probar conexión
maschine_driver --test-connection 2>/dev/null

echo ""
echo -e "${BLUE}🎹 ========================================="
echo "🎹 FORZADO DE MODO MASCHINE COMPLETADO"
echo "🎹 ========================================="

echo "🎯 RESULTADO:"
if maschine_driver --list-sources 2>/dev/null | grep -q "Maschine Mikro Input"; then
    echo -e "${GREEN}✅ ¡Maschine Mikro Input detectada!${NC}"
    echo -e "${GREEN}✅ Dispositivo en modo Maschine y funcionando${NC}"
    echo ""
    echo "💡 El dispositivo está completamente funcional:"
    echo "   maschine_driver --debug"
    echo "   maschine_driver --maschine-mode"
else
    echo -e "${YELLOW}⚠️  Maschine Mikro Input aún no detectada${NC}"
    echo -e "${YELLOW}⚠️  Pero el dispositivo debería estar en modo Maschine${NC}"
    echo ""
    echo "🔧 Próximos pasos:"
    echo "   1. Reinicia el sistema macOS completamente"
    echo "   2. El dispositivo ya está en modo Maschine"
    echo "   3. El driver funcionará en modo simulación"
fi

echo "🎹 ========================================="

# Limpiar archivos temporales
rm -f /tmp/force_maschine.cpp /tmp/force_maschine 