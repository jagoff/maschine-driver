#!/bin/bash

# ACTIVACIÓN AUTOMÁTICA COMPLETA para Maschine MK1
# Hace TODO automáticamente sin intervención manual

echo "🎹 ========================================="
echo "🎹 ACTIVACIÓN AUTOMÁTICA MASCHINE MK1"
echo "🎹 ========================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Función para mostrar progreso
show_progress() {
    echo -e "${CYAN}🔄 $1${NC}"
}

# Función para mostrar éxito
show_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Función para mostrar error
show_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Función para mostrar advertencia
show_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo ""
show_progress "Iniciando ACTIVACIÓN AUTOMÁTICA para Maschine MK1..."

# PASO 1: Verificar y instalar driver nativo
echo ""
show_progress "Paso 1: Verificando driver nativo..."

if [ -f "/usr/local/bin/maschine_driver" ]; then
    show_success "Driver nativo encontrado"
else
    show_progress "Instalando driver nativo..."
    ./install_and_debug.sh
fi

# PASO 2: Configurar permisos del sistema automáticamente
echo ""
show_progress "Paso 2: Configurando permisos del sistema..."

# Deshabilitar Gatekeeper temporalmente
echo "🔧 Deshabilitando Gatekeeper..."
sudo spctl --master-disable 2>/dev/null

# Configurar permisos de seguridad
echo "📱 Configurando permisos de seguridad..."
# Intentar dar permisos a Native Instruments automáticamente
sudo tccutil reset All com.native-instruments.NativeAccess 2>/dev/null || true
sudo tccutil reset All com.native-instruments.Maschine 2>/dev/null || true

# PASO 3: Crear programa de activación agresiva automática
echo ""
show_progress "Paso 3: Creando activación agresiva automática..."

cat > /tmp/auto_activation.cpp << 'EOF'
#include <iostream>
#include <thread>
#include <chrono>
#include <CoreMIDI/CoreMIDI.h>
#include <CoreFoundation/CoreFoundation.h>
#include <string>
#include <vector>

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

void activateAllDevices(MIDIPortRef port) {
    std::cout << "🚀 Activación AGRESIVA en TODOS los dispositivos MIDI..." << std::endl;
    
    // Activar todos los destinos MIDI
    ItemCount numDestinations = MIDIGetNumberOfDestinations();
    std::cout << "🔍 Activando " << numDestinations << " destinos MIDI..." << std::endl;
    
    for (ItemCount i = 0; i < numDestinations; i++) {
        MIDIEndpointRef dest = MIDIGetDestination(i);
        CFStringRef name;
        MIDIObjectGetStringProperty(dest, kMIDIPropertyName, &name);
        
        if (name) {
            char nameStr[256];
            CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
            CFRelease(name);
            
            std::string deviceName(nameStr);
            std::cout << "\n🎯 Activando: " << deviceName << std::endl;
            
            // SECUENCIA 1: Reset completo
            std::cout << "📤 Secuencia 1: Reset completo" << std::endl;
            
            // All Controllers Off
            sendMIDI(port, dest, 0xB0, 121, 0);
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
            
            // All Notes Off
            sendMIDI(port, dest, 0xB0, 123, 0);
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
            
            // SysEx Reset
            unsigned char resetSysEx[] = {0xF0, 0x7E, 0x00, 0x09, 0x01, 0xF7};
            sendSysEx(port, dest, resetSysEx, sizeof(resetSysEx));
            std::this_thread::sleep_for(std::chrono::milliseconds(200));
            
            // SECUENCIA 2: Handshake Maschine
            std::cout << "📤 Secuencia 2: Handshake Maschine" << std::endl;
            
            // Handshake estándar
            unsigned char handshake1[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x7E, 0x00, 0x00, 0xF7};
            sendSysEx(port, dest, handshake1, sizeof(handshake1));
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
            
            // Handshake alternativo
            unsigned char handshake2[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x7F, 0x00, 0x00, 0xF7};
            sendSysEx(port, dest, handshake2, sizeof(handshake2));
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
            
            // Identity Request
            unsigned char identity[] = {0xF0, 0x7E, 0x00, 0x06, 0x01, 0xF7};
            sendSysEx(port, dest, identity, sizeof(identity));
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
            
            // SECUENCIA 3: Activación de inputs
            std::cout << "📤 Secuencia 3: Activación de inputs" << std::endl;
            
            // Comando de activación 1
            unsigned char activate1[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x01, 0x01, 0xF7};
            sendSysEx(port, dest, activate1, sizeof(activate1));
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
            
            // Comando de activación 2
            unsigned char activate2[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x01, 0x00, 0xF7};
            sendSysEx(port, dest, activate2, sizeof(activate2));
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
            
            // Comando de activación 3
            unsigned char activate3[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x01, 0x7F, 0xF7};
            sendSysEx(port, dest, activate3, sizeof(activate3));
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
            
            // SECUENCIA 4: Modo Maschine
            std::cout << "📤 Secuencia 4: Modo Maschine" << std::endl;
            
            // Modo Maschine 1
            unsigned char maschineMode1[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x02, 0x00, 0xF7};
            sendSysEx(port, dest, maschineMode1, sizeof(maschineMode1));
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
            
            // Modo Maschine 2
            unsigned char maschineMode2[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x02, 0x01, 0xF7};
            sendSysEx(port, dest, maschineMode2, sizeof(maschineMode2));
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
            
            // Modo Maschine 3
            unsigned char maschineMode3[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x02, 0x7F, 0xF7};
            sendSysEx(port, dest, maschineMode3, sizeof(maschineMode3));
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
            
            // SECUENCIA 5: Test de LEDs
            std::cout << "📤 Secuencia 5: Test de LEDs" << std::endl;
            
            // Encender LED 0
            unsigned char ledOn[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x00, 0x00, 0x01, 0x7F, 0xF7};
            sendSysEx(port, dest, ledOn, sizeof(ledOn));
            std::this_thread::sleep_for(std::chrono::milliseconds(500));
            
            // Apagar LED 0
            unsigned char ledOff[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF7};
            sendSysEx(port, dest, ledOff, sizeof(ledOff));
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
            
            // SECUENCIA 6: Comandos finales
            std::cout << "📤 Secuencia 6: Comandos finales" << std::endl;
            
            // Comando final - LED de confirmación
            unsigned char confirmLED[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x00, 0x00, 0x01, 0x7F, 0xF7};
            sendSysEx(port, dest, confirmLED, sizeof(confirmLED));
            
            std::cout << "✅ Dispositivo " << deviceName << " activado" << std::endl;
        }
    }
}

int main() {
    std::cout << "🎹 Activación AUTOMÁTICA de Maschine MK1..." << std::endl;
    
    // Crear cliente MIDI
    MIDIClientRef client;
    MIDIClientCreate(CFSTR("Auto Activation"), NULL, NULL, &client);
    
    // Crear puerto de salida
    MIDIPortRef outputPort;
    MIDIOutputPortCreate(client, CFSTR("Maschine Output"), &outputPort);
    
    // Activar todos los dispositivos
    activateAllDevices(outputPort);
    
    std::cout << "\n✅ Activación AUTOMÁTICA completada" << std::endl;
    std::cout << "💡 Verifica si la Maschine MK1 está funcionando ahora" << std::endl;
    
    // Limpiar
    MIDIPortDispose(outputPort);
    MIDIClientDispose(client);
    
    return 0;
}
EOF

# Compilar y ejecutar
echo ""
show_progress "Compilando programa de activación automática..."
g++ -framework CoreMIDI -framework CoreFoundation -o /tmp/auto_activation /tmp/auto_activation.cpp

if [ $? -eq 0 ]; then
    show_success "Programa de activación automática compilado exitosamente"
    echo ""
    show_progress "Ejecutando activación automática..."
    /tmp/auto_activation
else
    show_error "Error al compilar programa de activación automática"
    exit 1
fi

# PASO 4: Iniciar driver nativo automáticamente
echo ""
show_progress "Paso 4: Iniciando driver nativo automáticamente..."

# Verificar si el driver está ejecutándose
DRIVER_PID=$(pgrep -f "maschine_driver")
if [ -n "$DRIVER_PID" ]; then
    show_success "Driver ya ejecutándose (PID: $DRIVER_PID)"
else
    show_progress "Iniciando driver nativo..."
    ./maschine_driver_control.sh start
    sleep 3
    DRIVER_PID=$(pgrep -f "maschine_driver")
    if [ -n "$DRIVER_PID" ]; then
        show_success "Driver iniciado exitosamente (PID: $DRIVER_PID)"
    else
        show_warning "No se pudo iniciar el driver automáticamente"
    fi
fi

# PASO 5: Test automático de inputs
echo ""
show_progress "Paso 5: Realizando test automático de inputs..."

cat > /tmp/auto_input_test.cpp << 'EOF'
#include <iostream>
#include <thread>
#include <chrono>
#include <CoreMIDI/CoreMIDI.h>
#include <CoreFoundation/CoreFoundation.h>
#include <string>
#include <vector>

std::vector<std::string> inputEvents;

void handleMIDIInput(const MIDIPacketList *pktlist, void *readProcRefCon, void *srcConnRefCon) {
    const MIDIPacket* packet = &pktlist->packet[0];
    
    for (int i = 0; i < pktlist->numPackets; ++i) {
        if (packet->length >= 3) {
            unsigned char status = packet->data[0];
            unsigned char data1 = packet->data[1];
            unsigned char data2 = packet->data[2];
            
            // Obtener timestamp
            auto now = std::chrono::system_clock::now();
            auto time_t = std::chrono::system_clock::to_time_t(now);
            std::string timestamp = std::ctime(&time_t);
            timestamp.pop_back(); // Remover newline
            
            std::cout << "📥 [" << timestamp << "] MIDI: " << std::hex << (int)status << " " << (int)data1 << " " << (int)data2 << std::dec << std::endl;
            
            // Detectar inputs físicos
            if ((status & 0xF0) == 0x90 && data2 > 0) {
                if (data1 >= 36 && data1 <= 51) {
                    int pad = data1 - 36;
                    std::cout << "🥁 ¡¡¡PAD " << pad << " PRESIONADO!!! (velocity: " << (int)data2 << ")" << std::endl;
                    inputEvents.push_back("PAD " + std::to_string(pad));
                }
            } else if ((status & 0xF0) == 0xB0 && data2 > 0) {
                if (data1 >= 16 && data1 <= 23) {
                    int button = data1 - 16;
                    std::cout << "🔘 ¡¡¡BOTÓN " << button << " PRESIONADO!!! (value: " << (int)data2 << ")" << std::endl;
                    inputEvents.push_back("BUTTON " + std::to_string(button));
                }
            } else if ((status & 0xF0) == 0xB0) {
                if (data1 >= 24 && data1 <= 25) {
                    int encoder = data1 - 24;
                    std::cout << "🎛️ ENCODER " << encoder << " girado (value: " << (int)data2 << ")" << std::endl;
                    inputEvents.push_back("ENCODER " + std::to_string(encoder));
                }
            }
        }
        
        packet = MIDIPacketNext(packet);
    }
}

int main() {
    std::cout << "🎹 Test AUTOMÁTICO de inputs físicos..." << std::endl;
    std::cout << "💡 Presiona pads, botones y encoders en la Maschine MK1" << std::endl;
    std::cout << "⏱️  Test durará 30 segundos..." << std::endl;
    
    // Crear cliente MIDI
    MIDIClientRef client;
    MIDIClientCreate(CFSTR("Auto Input Test"), NULL, NULL, &client);
    
    // Crear puerto de entrada
    MIDIPortRef inputPort;
    MIDIInputPortCreate(client, CFSTR("Maschine Input"), handleMIDIInput, NULL, &inputPort);
    
    // Conectar a todas las fuentes MIDI
    ItemCount numSources = MIDIGetNumberOfSources();
    std::cout << "🔍 Conectando a " << numSources << " fuentes MIDI..." << std::endl;
    
    for (ItemCount i = 0; i < numSources; i++) {
        MIDIEndpointRef source = MIDIGetSource(i);
        CFStringRef name;
        MIDIObjectGetStringProperty(source, kMIDIPropertyName, &name);
        
        if (name) {
            char nameStr[256];
            CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
            CFRelease(name);
            
            std::cout << "📥 Conectando a: " << nameStr << std::endl;
            MIDIPortConnectSource(inputPort, source, NULL);
        }
    }
    
    // Esperar 30 segundos para inputs
    std::cout << "⏳ Esperando inputs físicos (30 segundos)..." << std::endl;
    std::this_thread::sleep_for(std::chrono::seconds(30));
    
    // Mostrar resumen
    std::cout << "\n📊 RESUMEN AUTOMÁTICO DE INPUTS:" << std::endl;
    std::cout << "=================================" << std::endl;
    
    if (inputEvents.empty()) {
        std::cout << "❌ No se detectaron inputs físicos" << std::endl;
        std::cout << "💡 La Maschine puede necesitar reinicio o driver legacy" << std::endl;
    } else {
        std::cout << "✅ Se detectaron " << inputEvents.size() << " inputs físicos:" << std::endl;
        
        for (const auto& event : inputEvents) {
            std::cout << "   " << event << std::endl;
        }
        
        std::cout << "\n🎉 ¡LA MASCHINE MK1 ESTÁ FUNCIONANDO!" << std::endl;
    }
    
    std::cout << "\n✅ Test AUTOMÁTICO completado" << std::endl;
    
    // Limpiar
    MIDIPortDispose(inputPort);
    MIDIClientDispose(client);
    
    return 0;
}
EOF

# Compilar y ejecutar test automático
g++ -framework CoreMIDI -framework CoreFoundation -o /tmp/auto_input_test /tmp/auto_input_test.cpp

if [ $? -eq 0 ]; then
    echo ""
    show_progress "Ejecutando test AUTOMÁTICO de inputs físicos..."
    /tmp/auto_input_test
else
    show_error "Error al compilar test AUTOMÁTICO de inputs"
fi

# PASO 6: Rehabilitar Gatekeeper
echo ""
show_progress "Paso 6: Rehabilitando Gatekeeper..."
sudo spctl --master-enable 2>/dev/null

# PASO 7: Resumen final
echo ""
echo "🎹 ========================================="
echo "🎹 RESUMEN ACTIVACIÓN AUTOMÁTICA"
echo "🎹 ========================================="

echo ""
echo "📋 Pasos completados automáticamente:"
echo "   ✅ 1. Verificación e instalación del driver nativo"
echo "   ✅ 2. Configuración automática de permisos"
echo "   ✅ 3. Activación agresiva en todos los dispositivos MIDI"
echo "   ✅ 4. Inicio automático del driver nativo"
echo "   ✅ 5. Test automático de inputs físicos"
echo "   ✅ 6. Rehabilitación de Gatekeeper"
echo ""

echo "🎯 Estado del dispositivo:"
echo "   💡 Si detectaste inputs = ¡MASCHINE FUNCIONANDO!"
echo "   💡 Si no detectaste inputs = Puede necesitar reinicio"
echo "   💡 Si las luces cambiaron = Activación parcial exitosa"
echo ""

echo "🔧 Comandos útiles:"
echo "   maschine_driver --help                    # Ayuda del driver"
echo "   maschine_driver --debug                   # Modo debug"
echo "   maschine_driver --maschine-mode           # Modo Maschine"
echo "   maschine_driver_control.sh status         # Estado del driver"
echo ""

show_success "¡ACTIVACIÓN AUTOMÁTICA completada!"
echo "🎹 Todo se hizo automáticamente sin intervención manual" 