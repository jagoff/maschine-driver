#include <iostream>
#include <vector>
#include <string>
#include <map>
#include <CoreMIDI/CoreMIDI.h>
#include <CoreFoundation/CoreFoundation.h>
#include <unistd.h>

// Rebellion constants for Maschine Mikro
#define MASCHINE_MIKRO_MK2_ID 0x1200
#define MASCHINE_MIKRO_MK3_ID 0x1700
#define MASCHINE_MIKRO_MK1_ID 0x1110

// Message IDs from Rebellion
#define DEVICE_STATE_ON 0x3444e2b
#define DEVICE_STATE_OFF 0x3444e2d
#define PAD_DATA 0x3504e00
#define BTN_DATA 0x3734e00
#define KNOB_ROTATE 0x3654e00

// LED Colors from Rebellion
enum LEDColors {
    RED = 1,
    ORANGE = 2,
    LIGHT_ORANGE = 3,
    WARM_YELLOW = 4,
    YELLOW = 5,
    LIME = 6,
    GREEN = 7,
    MINT = 8,
    CYAN = 9,
    TURQUOISE = 10,
    BLUE = 11,
    PLUM = 12,
    VIOLET = 13,
    PURPLE = 14,
    MAGENTA = 15,
    FUCHSIA = 16,
    WHITE = 17
};

class RebellionMaschineDriver {
private:
    MIDIClientRef midiClient;
    MIDIPortRef midiOutPort;
    MIDIPortRef midiInPort;
    MIDIEndpointRef midiDestinations[10];
    MIDIEndpointRef midiSources[10];
    int numDestinations;
    int numSources;
    
    // Device state
    bool deviceConnected;
    std::string deviceName;
    int deviceId;
    
    // LED state
    bool padLEDs[16];
    bool buttonLEDs[8];
    
public:
    RebellionMaschineDriver() : midiClient(NULL), midiOutPort(NULL), midiInPort(NULL), 
                               numDestinations(0), numSources(0), deviceConnected(false) {
        // Initialize LED states
        for (int i = 0; i < 16; i++) padLEDs[i] = false;
        for (int i = 0; i < 8; i++) buttonLEDs[i] = false;
    }
    
    ~RebellionMaschineDriver() {
        disconnectDevice();
    }
    
    bool initialize() {
        std::cout << "🎹 Rebellion Maschine Driver - Inicializando..." << std::endl;
        
        // Create MIDI client
        OSStatus status = MIDIClientCreate(CFSTR("RebellionMaschineDriver"), NULL, NULL, &midiClient);
        if (status != noErr) {
            std::cerr << "Error creando cliente MIDI: " << status << std::endl;
            return false;
        }
        
        // Create output port
        status = MIDIOutputPortCreate(midiClient, CFSTR("Maschine Output"), &midiOutPort);
        if (status != noErr) {
            std::cerr << "Error creando puerto de salida MIDI: " << status << std::endl;
            return false;
        }
        
        // Discover MIDI destinations
        numDestinations = MIDIGetNumberOfDestinations();
        for (int i = 0; i < numDestinations && i < 10; i++) {
            midiDestinations[i] = MIDIGetDestination(i);
        }
        
        std::cout << "✅ MIDI inicializado correctamente" << std::endl;
        std::cout << "📡 Destinos MIDI encontrados: " << numDestinations << std::endl;
        
        return true;
    }
    
    bool connectDevice() {
        std::cout << "🔍 Buscando Maschine Mikro..." << std::endl;
        
        // Discover MIDI sources
        numSources = MIDIGetNumberOfSources();
        for (int i = 0; i < numSources && i < 10; i++) {
            midiSources[i] = MIDIGetSource(i);
        }
        
        // Look for Maschine device
        for (int i = 0; i < numSources; i++) {
            CFStringRef name;
            MIDIObjectGetStringProperty(midiSources[i], kMIDIPropertyName, &name);
            
            if (name) {
                char nameStr[256];
                CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
                
                std::cout << "📱 Dispositivo encontrado: " << nameStr << std::endl;
                
                if (strstr(nameStr, "Maschine") || strstr(nameStr, "Native Instruments")) {
                    deviceName = nameStr;
                    deviceConnected = true;
                    
                    // Create input port and connect to source
                    OSStatus status = MIDIInputPortCreate(midiClient, CFSTR("Maschine Input"), 
                                                        handleMIDIInput, this, &midiInPort);
                    if (status == noErr) {
                        status = MIDIPortConnectSource(midiInPort, midiSources[i], NULL);
                        if (status == noErr) {
                            std::cout << "✅ Conectado a: " << nameStr << std::endl;
                            return true;
                        }
                    }
                }
            }
        }
        
        std::cout << "❌ No se encontró Maschine Mikro" << std::endl;
        return false;
    }
    
    void disconnectDevice() {
        if (midiInPort) {
            MIDIPortDispose(midiInPort);
            midiInPort = NULL;
        }
        if (midiOutPort) {
            MIDIPortDispose(midiOutPort);
            midiOutPort = NULL;
        }
        if (midiClient) {
            MIDIClientDispose(midiClient);
            midiClient = NULL;
        }
        deviceConnected = false;
    }
    
    // Rebellion-style LED control
    void setPadLED(int pad, int color, int intensity = 127) {
        if (pad < 0 || pad >= 16) return;
        
        padLEDs[pad] = (intensity > 0);
        
        // Rebellion protocol: Send SysEx message
        // F0 00 20 3C 02 00 00 [pad] [color] [intensity] F7
        std::vector<unsigned char> sysex = {
            0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x00, 
            (unsigned char)pad, (unsigned char)color, (unsigned char)intensity, 0xF7
        };
        
        sendSysEx(sysex);
        std::cout << "💡 LED Pad " << pad << " -> Color " << color << " (intensity " << intensity << ")" << std::endl;
    }
    
    void setButtonLED(int button, int color, int intensity = 127) {
        if (button < 0 || button >= 8) return;
        
        buttonLEDs[button] = (intensity > 0);
        
        // Rebellion protocol: Send SysEx message
        // F0 00 20 3C 02 00 01 [button] [color] [intensity] F7
        std::vector<unsigned char> sysex = {
            0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x01, 
            (unsigned char)button, (unsigned char)color, (unsigned char)intensity, 0xF7
        };
        
        sendSysEx(sysex);
        std::cout << "💡 LED Botón " << button << " -> Color " << color << " (intensity " << intensity << ")" << std::endl;
    }
    
    void allPadsOff() {
        for (int i = 0; i < 16; i++) {
            setPadLED(i, 0, 0);
        }
    }
    
    void allPadsOn(int color = WHITE) {
        for (int i = 0; i < 16; i++) {
            setPadLED(i, color, 127);
        }
    }
    
    void testPattern() {
        std::cout << "🎨 Ejecutando patrón de prueba..." << std::endl;
        
        // Turn all off first
        allPadsOff();
        usleep(500000);
        
        // Turn on one by one with different colors
        int colors[] = {RED, GREEN, BLUE, YELLOW, MAGENTA, CYAN, WHITE};
        for (int i = 0; i < 16; i++) {
            setPadLED(i, colors[i % 7], 127);
            usleep(200000);
        }
        
        usleep(1000000);
        allPadsOff();
    }
    
    void rainbowPattern() {
        std::cout << "🌈 Ejecutando patrón arcoíris..." << std::endl;
        
        int colors[] = {RED, ORANGE, YELLOW, GREEN, CYAN, BLUE, MAGENTA};
        
        for (int round = 0; round < 3; round++) {
            for (int i = 0; i < 16; i++) {
                setPadLED(i, colors[i % 7], 127);
            }
            usleep(500000);
            
            for (int i = 0; i < 16; i++) {
                setPadLED(i, 0, 0);
            }
            usleep(500000);
        }
    }
    
    bool isConnected() const {
        return deviceConnected;
    }
    
    std::string getDeviceName() const {
        return deviceName;
    }

private:
    void sendSysEx(const std::vector<unsigned char>& data) {
        if (!deviceConnected || !midiOutPort) return;
        
        // Create MIDI packet list
        MIDIPacketList packetList;
        MIDIPacket* packet = MIDIPacketListInit(&packetList);
        
        packet = MIDIPacketListAdd(&packetList, sizeof(packetList), packet, 0, data.size(), data.data());
        
        if (packet) {
            // Send to all destinations
            for (int i = 0; i < numDestinations; i++) {
                MIDISend(midiOutPort, midiDestinations[i], &packetList);
            }
        }
    }
    
    static void handleMIDIInput(const MIDIPacketList* packetList, void* readProcRefCon, void* srcConnRefCon) {
        RebellionMaschineDriver* driver = static_cast<RebellionMaschineDriver*>(readProcRefCon);
        driver->processMIDIInput(packetList);
    }
    
    void processMIDIInput(const MIDIPacketList* packetList) {
        const MIDIPacket* packet = &packetList->packet[0];
        
        for (int i = 0; i < packetList->numPackets; i++) {
            unsigned char status = packet->data[0];
            unsigned char data1 = packet->data[1];
            unsigned char data2 = packet->data[2];
            
            // Handle Note On/Off (pads)
            if ((status & 0xF0) == 0x90) { // Note On
                int pad = data1 - 36; // Pads start at MIDI note 36
                if (pad >= 0 && pad < 16) {
                    std::cout << "🥁 Pad " << pad << " presionado (velocity: " << (int)data2 << ")" << std::endl;
                    // Light up the pad
                    setPadLED(pad, GREEN, data2);
                }
            } else if ((status & 0xF0) == 0x80) { // Note Off
                int pad = data1 - 36;
                if (pad >= 0 && pad < 16) {
                    std::cout << "🥁 Pad " << pad << " liberado" << std::endl;
                    // Turn off the pad
                    setPadLED(pad, 0, 0);
                }
            }
            // Handle Control Change (buttons/encoders)
            else if ((status & 0xF0) == 0xB0) { // Control Change
                if (data1 >= 16 && data1 <= 23) { // Buttons
                    int button = data1 - 16;
                    if (data2 > 0) {
                        std::cout << "🔘 Botón " << button << " presionado (value: " << (int)data2 << ")" << std::endl;
                        setButtonLED(button, RED, 127);
                    } else {
                        std::cout << "🔘 Botón " << button << " liberado" << std::endl;
                        setButtonLED(button, 0, 0);
                    }
                } else if (data1 >= 24 && data1 <= 25) { // Encoders
                    int encoder = data1 - 24;
                    std::cout << "🎛️ Encoder " << encoder << " girado (value: " << (int)data2 << ")" << std::endl;
                }
            }
            
            packet = MIDIPacketNext(packet);
        }
    }
};

int main() {
    std::cout << "🎹 =========================================" << std::endl;
    std::cout << "🎹 Rebellion Maschine Driver v1.0" << std::endl;
    std::cout << "🎹 Basado en el proyecto Rebellion" << std::endl;
    std::cout << "🎹 =========================================" << std::endl;
    
    RebellionMaschineDriver driver;
    
    if (!driver.initialize()) {
        std::cerr << "❌ Error inicializando el driver" << std::endl;
        return 1;
    }
    
    if (!driver.connectDevice()) {
        std::cerr << "❌ No se pudo conectar al dispositivo" << std::endl;
        return 1;
    }
    
    std::cout << "\n🎯 Dispositivo conectado: " << driver.getDeviceName() << std::endl;
    std::cout << "\n📋 Comandos disponibles:" << std::endl;
    std::cout << "1. test - Patrón de prueba" << std::endl;
    std::cout << "2. rainbow - Patrón arcoíris" << std::endl;
    std::cout << "3. allon - Encender todos los pads" << std::endl;
    std::cout << "4. alloff - Apagar todos los pads" << std::endl;
    std::cout << "5. quit - Salir" << std::endl;
    std::cout << "\n💡 Presiona pads y botones en tu Maschine Mikro para ver los inputs!" << std::endl;
    
    std::string command;
    while (true) {
        std::cout << "\n🎹 > ";
        std::getline(std::cin, command);
        
        if (command == "test") {
            driver.testPattern();
        } else if (command == "rainbow") {
            driver.rainbowPattern();
        } else if (command == "allon") {
            driver.allPadsOn();
        } else if (command == "alloff") {
            driver.allPadsOff();
        } else if (command == "quit") {
            break;
        } else if (command == "1") {
            driver.testPattern();
        } else if (command == "2") {
            driver.rainbowPattern();
        } else if (command == "3") {
            driver.allPadsOn();
        } else if (command == "4") {
            driver.allPadsOff();
        } else if (command == "5") {
            break;
        } else {
            std::cout << "❓ Comando no reconocido: '" << command << "'" << std::endl;
        }
    }
    
    std::cout << "👋 ¡Hasta luego!" << std::endl;
    return 0;
} 