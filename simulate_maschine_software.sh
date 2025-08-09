#!/bin/bash

# Script para simular el comportamiento del software oficial de Maschine
# y activar correctamente el dispositivo

echo "🎹 ========================================="
echo "🎹 SIMULANDO SOFTWARE MASCHINE OFICIAL"
echo "🎹 ========================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}🔍 Paso 1: Verificando estado del dispositivo...${NC}"

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
echo -e "${BLUE}🔍 Paso 2: Simulando secuencia de inicio de Maschine...${NC}"

# Crear un programa más completo que simule el software oficial
cat > /tmp/maschine_simulator.cpp << 'EOF'
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
    std::cout << "📤 SysEx enviado: ";
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
    printf("📤 MIDI enviado: %02X %02X %02X\n", status, data1, data2);
}

int main() {
    std::cout << "🎹 Simulando software oficial de Maschine..." << std::endl;
    
    // Crear cliente MIDI
    MIDIClientRef client;
    MIDIClientCreate(CFSTR("Maschine Simulator"), NULL, NULL, &client);
    
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
    
    std::cout << "🚀 Iniciando secuencia de activación..." << std::endl;
    
    // Secuencia 1: Reset del dispositivo
    std::cout << "\n📤 Secuencia 1: Reset del dispositivo" << std::endl;
    unsigned char resetSysex[] = {0xF0, 0x00, 0x20, 0x37, 0x01, 0x00, 0x00, 0xF7};
    sendSysEx(outputPort, maschineOutput, resetSysex, sizeof(resetSysex));
    std::this_thread::sleep_for(std::chrono::milliseconds(200));
    
    // Secuencia 2: Inicialización Maschine
    std::cout << "\n📤 Secuencia 2: Inicialización Maschine" << std::endl;
    unsigned char initSysex[] = {0xF0, 0x00, 0x20, 0x37, 0x01, 0x00, 0x01, 0xF7};
    sendSysEx(outputPort, maschineOutput, initSysex, sizeof(initSysex));
    std::this_thread::sleep_for(std::chrono::milliseconds(200));
    
    // Secuencia 3: Modo Maschine
    std::cout << "\n📤 Secuencia 3: Activando modo Maschine" << std::endl;
    unsigned char maschineModeSysex[] = {0xF0, 0x00, 0x20, 0x37, 0x01, 0x00, 0x02, 0xF7};
    sendSysEx(outputPort, maschineOutput, maschineModeSysex, sizeof(maschineModeSysex));
    std::this_thread::sleep_for(std::chrono::milliseconds(200));
    
    // Secuencia 4: Configuración de pads
    std::cout << "\n📤 Secuencia 4: Configurando pads" << std::endl;
    for (int i = 0; i < 16; i++) {
        // Configurar cada pad
        unsigned char padConfig[] = {0xF0, 0x00, 0x20, 0x37, 0x01, 0x10, (unsigned char)i, 0x01, 0xF7};
        sendSysEx(outputPort, maschineOutput, padConfig, sizeof(padConfig));
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }
    
    // Secuencia 5: Configuración de botones
    std::cout << "\n📤 Secuencia 5: Configurando botones" << std::endl;
    for (int i = 0; i < 8; i++) {
        // Configurar cada botón
        unsigned char buttonConfig[] = {0xF0, 0x00, 0x20, 0x37, 0x01, 0x20, (unsigned char)i, 0x01, 0xF7};
        sendSysEx(outputPort, maschineOutput, buttonConfig, sizeof(buttonConfig));
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }
    
    // Secuencia 6: Configuración de encoders
    std::cout << "\n📤 Secuencia 6: Configurando encoders" << std::endl;
    for (int i = 0; i < 2; i++) {
        // Configurar cada encoder
        unsigned char encoderConfig[] = {0xF0, 0x00, 0x20, 0x37, 0x01, 0x30, (unsigned char)i, 0x01, 0xF7};
        sendSysEx(outputPort, maschineOutput, encoderConfig, sizeof(encoderConfig));
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }
    
    // Secuencia 7: Comando de inicio
    std::cout << "\n📤 Secuencia 7: Enviando comando de inicio" << std::endl;
    unsigned char startSysex[] = {0xF0, 0x00, 0x20, 0x37, 0x01, 0x00, 0x03, 0xF7};
    sendSysEx(outputPort, maschineOutput, startSysex, sizeof(startSysex));
    std::this_thread::sleep_for(std::chrono::milliseconds(200));
    
    // Secuencia 8: Simular presionar un pad para activar
    std::cout << "\n📤 Secuencia 8: Simulando activación por pad" << std::endl;
    sendMIDI(outputPort, maschineOutput, 0x90, 0x24, 0x7F); // Note On, pad 36
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    sendMIDI(outputPort, maschineOutput, 0x80, 0x24, 0x00); // Note Off, pad 36
    
    // Secuencia 9: Comando final de activación
    std::cout << "\n📤 Secuencia 9: Comando final de activación" << std::endl;
    unsigned char finalSysex[] = {0xF0, 0x00, 0x20, 0x37, 0x01, 0x00, 0x04, 0xF7};
    sendSysEx(outputPort, maschineOutput, finalSysex, sizeof(finalSysex));
    
    std::cout << "\n✅ Secuencia de activación completada" << std::endl;
    std::cout << "💡 El dispositivo debería cambiar de modo ahora" << std::endl;
    
    // Limpiar
    MIDIPortDispose(outputPort);
    MIDIClientDispose(client);
    
    return 0;
}
EOF

# Compilar y ejecutar el simulador
echo "🔨 Compilando simulador de software oficial..."
g++ -framework CoreMIDI -framework CoreFoundation -o /tmp/maschine_simulator /tmp/maschine_simulator.cpp

if [ $? -eq 0 ]; then
    echo "✅ Simulador compilado"
    echo "🚀 Ejecutando simulador..."
    /tmp/maschine_simulator
else
    echo -e "${RED}❌ Error al compilar simulador${NC}"
fi

echo ""
echo -e "${BLUE}🔍 Paso 3: Verificando respuesta del dispositivo...${NC}"

# Esperar y verificar logs
sleep 3
echo "📄 Actividad reciente en logs:"
tail -10 /var/log/maschine_driver.log 2>/dev/null || echo "   No hay logs disponibles"

echo ""
echo -e "${BLUE}🔍 Paso 4: Estado final...${NC}"

echo "🎯 El dispositivo debería haber cambiado de:"
echo "   'start maschine or press shift+f1 for midi mode'"
echo "   a un modo activo con LEDs encendidos"
echo ""
echo "💡 Si el dispositivo no cambió:"
echo "   1. Presiona SHIFT + F1 en el dispositivo"
echo "   2. O desconecta y reconecta el USB"
echo "   3. O ejecuta: ./maschine_driver_control.sh restart"

echo ""
echo -e "${BLUE}🎹 ========================================="
echo "🎹 SIMULACIÓN COMPLETADA"
echo "🎹 ========================================="

if [ -n "$DRIVER_PID" ]; then
    echo -e "${GREEN}✅ Driver activo y simulador ejecutado${NC}"
    echo "🎯 Dispositivo debería estar en modo activo"
    echo "💡 Verifica el display del dispositivo"
else
    echo -e "${RED}❌ Driver no está ejecutándose${NC}"
fi

echo "🎹 ========================================="

# Limpiar archivos temporales
rm -f /tmp/maschine_simulator.cpp /tmp/maschine_simulator 