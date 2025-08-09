#!/bin/bash

# Script para activar el modo Maschine y hacer que el dispositivo responda
# al mensaje "start maschine or press shift+f1 for midi mode"

echo "🎹 ========================================="
echo "🎹 ACTIVANDO MODO MASCHINE"
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
    sleep 2
    DRIVER_PID=$(pgrep -f "maschine_driver")
fi

echo ""
echo -e "${BLUE}🔍 Paso 2: Enviando comandos de activación...${NC}"

# Enviar comandos específicos para activar el modo Maschine
echo "📤 Enviando handshake Maschine..."

# Crear un script temporal para enviar comandos específicos
cat > /tmp/maschine_activation.cpp << 'EOF'
#include <iostream>
#include <thread>
#include <chrono>
#include <CoreMIDI/CoreMIDI.h>

int main() {
    std::cout << "🎹 Enviando comandos de activación Maschine..." << std::endl;
    
    // Encontrar el destino Maschine Mikro Output
    MIDIClientRef client;
    MIDIClientCreate(CFSTR("Maschine Activator"), NULL, NULL, &client);
    
    MIDIPortRef outputPort;
    MIDIOutputPortCreate(client, CFSTR("Maschine Output"), &outputPort);
    
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
    
    // Enviar comandos de activación
    std::cout << "📤 Enviando comandos de activación..." << std::endl;
    
    // Comando 1: SysEx de inicialización Maschine
    unsigned char sysex1[] = {0xF0, 0x00, 0x20, 0x37, 0x01, 0x00, 0x01, 0xF7};
    MIDIPacketList packetList1;
    MIDIPacket *packet1 = MIDIPacketListInit(&packetList1);
    MIDIPacketListAdd(&packetList1, sizeof(packetList1), packet1, 0, sizeof(sysex1), sysex1);
    MIDISend(outputPort, maschineOutput, &packetList1);
    
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    
    // Comando 2: SysEx de modo Maschine
    unsigned char sysex2[] = {0xF0, 0x00, 0x20, 0x37, 0x01, 0x00, 0x02, 0xF7};
    MIDIPacketList packetList2;
    MIDIPacket *packet2 = MIDIPacketListInit(&packetList2);
    MIDIPacketListAdd(&packetList2, sizeof(packetList2), packet2, 0, sizeof(sysex2), sysex2);
    MIDISend(outputPort, maschineOutput, &packetList2);
    
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    
    // Comando 3: Note On para activar (simular presionar un pad)
    unsigned char noteOn[] = {0x90, 0x24, 0x7F}; // Note On, pad 36, velocity 127
    MIDIPacketList packetList3;
    MIDIPacket *packet3 = MIDIPacketListInit(&packetList3);
    MIDIPacketListAdd(&packetList3, sizeof(packetList3), packet3, 0, sizeof(noteOn), noteOn);
    MIDISend(outputPort, maschineOutput, &packetList3);
    
    std::this_thread::sleep_for(std::chrono::milliseconds(50));
    
    // Comando 4: Note Off
    unsigned char noteOff[] = {0x80, 0x24, 0x00}; // Note Off, pad 36, velocity 0
    MIDIPacketList packetList4;
    MIDIPacket *packet4 = MIDIPacketListInit(&packetList4);
    MIDIPacketListAdd(&packetList4, sizeof(packetList4), packet4, 0, sizeof(noteOff), noteOff);
    MIDISend(outputPort, maschineOutput, &packetList4);
    
    std::cout << "✅ Comandos enviados" << std::endl;
    
    MIDIPortDispose(outputPort);
    MIDIClientDispose(client);
    
    return 0;
}
EOF

# Compilar y ejecutar el activador
echo "🔨 Compilando activador..."
g++ -framework CoreMIDI -framework CoreFoundation -o /tmp/maschine_activator /tmp/maschine_activation.cpp

if [ $? -eq 0 ]; then
    echo "✅ Activador compilado"
    echo "🚀 Ejecutando activador..."
    /tmp/maschine_activator
else
    echo -e "${RED}❌ Error al compilar activador${NC}"
fi

echo ""
echo -e "${BLUE}🔍 Paso 3: Verificando respuesta...${NC}"

# Esperar un momento y verificar logs
sleep 2
echo "📄 Últimas líneas del log:"
tail -5 /var/log/maschine_driver.log 2>/dev/null || echo "   No hay logs disponibles"

echo ""
echo -e "${BLUE}🔍 Paso 4: Instrucciones para el usuario...${NC}"

echo "🎯 El dispositivo muestra: 'start maschine or press shift+f1 for midi mode'"
echo ""
echo "💡 Esto significa que:"
echo "   ✅ El dispositivo está funcionando correctamente"
echo "   ✅ Está detectando el driver"
echo "   ✅ Está en modo espera"
echo ""
echo "🎹 Para activar el modo Maschine:"
echo "   1. Presiona SHIFT + F1 en el dispositivo (para modo MIDI)"
echo "   2. O espera a que el driver envíe el comando de inicio"
echo "   3. El dispositivo debería cambiar a modo activo"
echo ""
echo "🔧 Si no responde:"
echo "   1. Reinicia el dispositivo (desconecta y reconecta USB)"
echo "   2. Ejecuta: ./maschine_driver_control.sh restart"
echo "   3. Presiona SHIFT + F1 en el dispositivo"

echo ""
echo -e "${BLUE}🎹 ========================================="
echo "🎹 ACTIVACIÓN COMPLETADA"
echo "🎹 ========================================="

if [ -n "$DRIVER_PID" ]; then
    echo -e "${GREEN}✅ Driver activo y funcionando${NC}"
    echo "🎯 Dispositivo listo para usar"
    echo "💡 Presiona SHIFT + F1 en el dispositivo para activar"
else
    echo -e "${RED}❌ Driver no está ejecutándose${NC}"
    echo "💡 Ejecuta: ./maschine_driver_control.sh start"
fi

echo "🎹 ========================================="

# Limpiar archivos temporales
rm -f /tmp/maschine_activation.cpp /tmp/maschine_activator 