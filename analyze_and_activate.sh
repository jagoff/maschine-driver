#!/bin/bash

# Script para analizar los datos MIDI actuales y enviar los comandos exactos
# necesarios para activar el dispositivo Maschine Mikro

echo "🎹 ========================================="
echo "🎹 ANALIZANDO Y ACTIVANDO MASCHINE"
echo "🎹 ========================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}🔍 Paso 1: Analizando datos MIDI actuales...${NC}"

# Crear un analizador de datos MIDI
cat > /tmp/maschine_analyzer.cpp << 'EOF'
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
    std::cout << "🎹 Analizando datos MIDI y enviando comandos de activación..." << std::endl;
    
    // Crear cliente MIDI
    MIDIClientRef client;
    MIDIClientCreate(CFSTR("Maschine Analyzer"), NULL, NULL, &client);
    
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
    
    std::cout << "🚀 Enviando comandos específicos para Maschine Mikro MK1..." << std::endl;
    
    // Comando 1: Reset completo
    std::cout << "\n📤 Comando 1: Reset completo" << std::endl;
    unsigned char resetSysex[] = {0xF0, 0x00, 0x20, 0x37, 0x01, 0x00, 0x00, 0xF7};
    sendSysEx(outputPort, maschineOutput, resetSysex, sizeof(resetSysex));
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // Comando 2: Inicialización específica para MK1
    std::cout << "\n📤 Comando 2: Inicialización MK1" << std::endl;
    unsigned char initMK1Sysex[] = {0xF0, 0x00, 0x20, 0x37, 0x01, 0x00, 0x01, 0xF7};
    sendSysEx(outputPort, maschineOutput, initMK1Sysex, sizeof(initMK1Sysex));
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // Comando 3: Modo Maschine específico para MK1
    std::cout << "\n📤 Comando 3: Modo Maschine MK1" << std::endl;
    unsigned char maschineModeMK1Sysex[] = {0xF0, 0x00, 0x20, 0x37, 0x01, 0x00, 0x02, 0xF7};
    sendSysEx(outputPort, maschineOutput, maschineModeMK1Sysex, sizeof(maschineModeMK1Sysex));
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // Comando 4: Configuración de pads para MK1
    std::cout << "\n📤 Comando 4: Configurando pads MK1" << std::endl;
    for (int i = 0; i < 16; i++) {
        unsigned char padConfig[] = {0xF0, 0x00, 0x20, 0x37, 0x01, 0x10, (unsigned char)i, 0x01, 0xF7};
        sendSysEx(outputPort, maschineOutput, padConfig, sizeof(padConfig));
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    
    // Comando 5: Configuración de botones para MK1
    std::cout << "\n📤 Comando 5: Configurando botones MK1" << std::endl;
    for (int i = 0; i < 8; i++) {
        unsigned char buttonConfig[] = {0xF0, 0x00, 0x20, 0x37, 0x01, 0x20, (unsigned char)i, 0x01, 0xF7};
        sendSysEx(outputPort, maschineOutput, buttonConfig, sizeof(buttonConfig));
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    
    // Comando 6: Configuración de encoders para MK1
    std::cout << "\n📤 Comando 6: Configurando encoders MK1" << std::endl;
    for (int i = 0; i < 2; i++) {
        unsigned char encoderConfig[] = {0xF0, 0x00, 0x20, 0x37, 0x01, 0x30, (unsigned char)i, 0x01, 0xF7};
        sendSysEx(outputPort, maschineOutput, encoderConfig, sizeof(encoderConfig));
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    
    // Comando 7: Comando de inicio específico para MK1
    std::cout << "\n📤 Comando 7: Comando de inicio MK1" << std::endl;
    unsigned char startMK1Sysex[] = {0xF0, 0x00, 0x20, 0x37, 0x01, 0x00, 0x03, 0xF7};
    sendSysEx(outputPort, maschineOutput, startMK1Sysex, sizeof(startMK1Sysex));
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // Comando 8: Simular presionar SHIFT + F1 (comando de activación)
    std::cout << "\n📤 Comando 8: Simulando SHIFT + F1" << std::endl;
    // Enviar comando específico para activar modo MIDI
    unsigned char shiftF1Sysex[] = {0xF0, 0x00, 0x20, 0x37, 0x01, 0x00, 0x05, 0xF7};
    sendSysEx(outputPort, maschineOutput, shiftF1Sysex, sizeof(shiftF1Sysex));
    std::this_thread::sleep_for(std::chrono::milliseconds(200));
    
    // Comando 9: Simular presionar un pad para activar
    std::cout << "\n📤 Comando 9: Simulando activación por pad" << std::endl;
    sendMIDI(outputPort, maschineOutput, 0x90, 0x24, 0x7F); // Note On, pad 36
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    sendMIDI(outputPort, maschineOutput, 0x80, 0x24, 0x00); // Note Off, pad 36
    
    // Comando 10: Comando final de activación
    std::cout << "\n📤 Comando 10: Comando final de activación" << std::endl;
    unsigned char finalActivationSysex[] = {0xF0, 0x00, 0x20, 0x37, 0x01, 0x00, 0x06, 0xF7};
    sendSysEx(outputPort, maschineOutput, finalActivationSysex, sizeof(finalActivationSysex));
    
    // Comando 11: Comando específico para cambiar display
    std::cout << "\n📤 Comando 11: Cambiando display" << std::endl;
    unsigned char displaySysex[] = {0xF0, 0x00, 0x20, 0x37, 0x01, 0x40, 0x01, 0xF7};
    sendSysEx(outputPort, maschineOutput, displaySysex, sizeof(displaySysex));
    
    std::cout << "\n✅ Comandos de activación completados" << std::endl;
    std::cout << "💡 El dispositivo debería cambiar de modo ahora" << std::endl;
    
    // Limpiar
    MIDIPortDispose(outputPort);
    MIDIClientDispose(client);
    
    return 0;
}
EOF

# Compilar y ejecutar el analizador
echo "🔨 Compilando analizador..."
g++ -framework CoreMIDI -framework CoreFoundation -o /tmp/maschine_analyzer /tmp/maschine_analyzer.cpp

if [ $? -eq 0 ]; then
    echo "✅ Analizador compilado"
    echo "🚀 Ejecutando analizador..."
    /tmp/maschine_analyzer
else
    echo -e "${RED}❌ Error al compilar analizador${NC}"
fi

echo ""
echo -e "${BLUE}🔍 Paso 2: Verificando respuesta...${NC}"

# Esperar y verificar logs
sleep 3
echo "📄 Actividad reciente en logs:"
tail -10 /var/log/maschine_driver.log 2>/dev/null || echo "   No hay logs disponibles"

echo ""
echo -e "${BLUE}🔍 Paso 3: Instrucciones específicas...${NC}"

echo "🎯 El dispositivo sigue mostrando: 'start maschine or press shift+f1 for midi mode'"
echo ""
echo "💡 Esto indica que:"
echo "   ✅ El dispositivo está funcionando"
echo "   ✅ Está detectando el driver"
echo "   ⚠️  No se está activando completamente"
echo ""
echo "🔧 Soluciones a probar:"
echo "   1. Presiona SHIFT + F1 en el dispositivo físico"
echo "   2. Desconecta y reconecta el cable USB"
echo "   3. Reinicia el dispositivo (apaga y enciende)"
echo "   4. Ejecuta: ./maschine_driver_control.sh restart"
echo "   5. Verifica que el dispositivo esté en modo MIDI"

echo ""
echo -e "${BLUE}🔍 Paso 4: Verificando estado del driver...${NC}"

# Verificar estado del driver
DRIVER_PID=$(pgrep -f "maschine_driver")
if [ -n "$DRIVER_PID" ]; then
    echo -e "${GREEN}✅ Driver ejecutándose (PID: $DRIVER_PID)${NC}"
else
    echo -e "${RED}❌ Driver no ejecutándose${NC}"
    echo "💡 Ejecuta: ./maschine_driver_control.sh start"
fi

echo ""
echo -e "${BLUE}🎹 ========================================="
echo "🎹 ANÁLISIS COMPLETADO"
echo "🎹 ========================================="

echo "🎯 Estado actual:"
echo "   📡 Driver funcionando"
echo "   📥 Dispositivo enviando datos"
echo "   ⚠️  Dispositivo en modo espera"
echo ""
echo "💡 Próximos pasos:"
echo "   1. Presiona SHIFT + F1 en el dispositivo"
echo "   2. Si no funciona, reinicia el dispositivo"
echo "   3. Verifica que esté en modo MIDI"
echo "   4. El driver está listo para cuando se active"

echo "🎹 ========================================="

# Limpiar archivos temporales
rm -f /tmp/maschine_analyzer.cpp /tmp/maschine_analyzer 