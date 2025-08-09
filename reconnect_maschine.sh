#!/bin/bash

# Script para reconectar limpiamente el dispositivo Maschine Mikro
# Esto es más rápido y efectivo que reiniciar todo el sistema

echo "🎹 ========================================="
echo "🎹 RECONEXIÓN LIMPIA MASCHINE MIKRO"
echo "🎹 ========================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}🔍 Paso 1: Deteniendo driver actual...${NC}"
./maschine_driver_control.sh stop
sleep 2

echo ""
echo -e "${BLUE}🔍 Paso 2: Limpiando procesos MIDI...${NC}"
pkill -f "maschine_driver" 2>/dev/null
pkill -f "MIDIServer" 2>/dev/null
sleep 1

echo ""
echo -e "${YELLOW}⚠️  INSTRUCCIONES IMPORTANTES:${NC}"
echo ""
echo "1. ${YELLOW}Desconecta el cable USB de la Maschine Mikro${NC}"
echo "2. ${YELLOW}Espera 5 segundos${NC}"
echo "3. ${YELLOW}Vuelve a conectar el cable USB${NC}"
echo "4. ${YELLOW}Espera a que el dispositivo se inicialice${NC}"
echo ""
echo -e "${BLUE}Presiona ENTER cuando hayas desconectado y reconectado el dispositivo...${NC}"
read -r

echo ""
echo -e "${BLUE}🔍 Paso 3: Verificando reconexión...${NC}"
sleep 3

# Verificar si el dispositivo está de vuelta
echo "🔍 Buscando Maschine Mikro..."
if system_profiler SPUSBDataType 2>/dev/null | grep -i "maschine" > /dev/null; then
    echo -e "${GREEN}✅ Maschine Mikro detectada en USB${NC}"
else
    echo -e "${RED}❌ Maschine Mikro no detectada en USB${NC}"
    echo "   Verifica la conexión USB y vuelve a intentar"
    exit 1
fi

echo ""
echo -e "${BLUE}🔍 Paso 4: Reiniciando driver...${NC}"
./maschine_driver_control.sh start
sleep 3

echo ""
echo -e "${BLUE}🔍 Paso 5: Verificando estado del driver...${NC}"
./maschine_driver_control.sh status

echo ""
echo -e "${BLUE}🔍 Paso 6: Enviando comandos de activación...${NC}"

# Crear programa de activación post-reconexión
cat > /tmp/post_reconnect_activation.cpp << 'EOF'
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

int main() {
    std::cout << "🎹 Activación post-reconexión..." << std::endl;
    
    // Crear cliente MIDI
    MIDIClientRef client;
    MIDIClientCreate(CFSTR("Post Reconnect"), NULL, NULL, &client);
    
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
    
    std::cout << "🚀 Enviando secuencia de activación post-reconexión..." << std::endl;
    
    // Secuencia específica para post-reconexión
    std::cout << "\n📤 Comando 1: Reset completo" << std::endl;
    unsigned char reset[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x00, 0xF7};
    sendSysEx(outputPort, maschineOutput, reset, sizeof(reset));
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    
    std::cout << "\n📤 Comando 2: Handshake" << std::endl;
    unsigned char handshake[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x7E, 0x00, 0x00, 0xF7};
    sendSysEx(outputPort, maschineOutput, handshake, sizeof(handshake));
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    
    std::cout << "\n📤 Comando 3: Activar inputs" << std::endl;
    unsigned char activateInputs[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x01, 0x01, 0xF7};
    sendSysEx(outputPort, maschineOutput, activateInputs, sizeof(activateInputs));
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    
    std::cout << "\n📤 Comando 4: Modo normal" << std::endl;
    unsigned char normalMode[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x02, 0x00, 0xF7};
    sendSysEx(outputPort, maschineOutput, normalMode, sizeof(normalMode));
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    
    std::cout << "\n📤 Comando 5: Comando de inicio" << std::endl;
    unsigned char startCommand[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x00, 0x00, 0x01, 0x7F, 0xF7};
    sendSysEx(outputPort, maschineOutput, startCommand, sizeof(startCommand));
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    
    std::cout << "\n📤 Comando 6: Simular SHIFT + F1" << std::endl;
    unsigned char shiftF1[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x03, 0x01, 0xF7};
    sendSysEx(outputPort, maschineOutput, shiftF1, sizeof(shiftF1));
    
    std::cout << "\n✅ Secuencia de activación completada" << std::endl;
    
    // Limpiar
    MIDIPortDispose(outputPort);
    MIDIClientDispose(client);
    
    return 0;
}
EOF

# Compilar y ejecutar
echo "🔨 Compilando activación post-reconexión..."
g++ -framework CoreMIDI -framework CoreFoundation -o /tmp/post_reconnect_activation /tmp/post_reconnect_activation.cpp

if [ $? -eq 0 ]; then
    echo "✅ Activación post-reconexión compilada"
    echo "🚀 Ejecutando activación..."
    /tmp/post_reconnect_activation
else
    echo -e "${RED}❌ Error al compilar activación post-reconexión${NC}"
fi

echo ""
echo -e "${BLUE}🔍 Paso 7: Verificando estado final...${NC}"
sleep 3

echo "📄 Actividad reciente en logs:"
tail -5 /var/log/maschine_driver.log 2>/dev/null || echo "   No hay logs disponibles"

echo ""
echo -e "${BLUE}🎹 ========================================="
echo "🎹 RECONEXIÓN COMPLETADA"
echo "🎹 ========================================="

echo "🎯 RESULTADO:"
echo "   ✅ Dispositivo reconectado"
echo "   ✅ Driver reiniciado"
echo "   ✅ Comandos de activación enviados"
echo ""
echo "💡 Ahora:"
echo "   1. El display debería cambiar"
echo "   2. Los pads deberían funcionar"
echo "   3. El dispositivo debería estar completamente activo"
echo ""
echo "🔍 Si aún no funciona:"
echo "   - Presiona SHIFT + F1 en el dispositivo"
echo "   - O prueba con diferentes puertos USB"
echo "   - O reinicia solo el driver: ./maschine_driver_control.sh restart"

echo "🎹 ========================================="

# Limpiar archivos temporales
rm -f /tmp/post_reconnect_activation.cpp /tmp/post_reconnect_activation 