#include "MaschineMikroDriver_User.h"
#include <iostream>
#include <thread>
#include <chrono>

MaschineMikroDriverUser::MaschineMikroDriverUser() {
    maschineSoftwareConnected = false;
    maschineSoftwarePath = "";
    midiClient = NULL;
    midiOutPort = NULL;
    midiInPort = NULL;
    numDestinations = 0;
    initializeMaschineState();
}

MaschineMikroDriverUser::~MaschineMikroDriverUser() {
    disconnectDevice();
}

bool MaschineMikroDriverUser::initialize() {
    std::cout << "[Maschine] Inicializando driver en modo Maschine nativo..." << std::endl;
    
    // Inicializar CoreMIDI
    OSStatus status = MIDIClientCreate(CFSTR("Maschine Mikro Driver"), NULL, NULL, &midiClient);
    if (status != noErr) {
        std::cout << "[Error] No se pudo crear cliente MIDI: " << status << std::endl;
        return false;
    }
    
    // Crear puerto de salida MIDI
    status = MIDIOutputPortCreate(midiClient, CFSTR("Maschine Output"), &midiOutPort);
    if (status != noErr) {
        std::cout << "[Error] No se pudo crear puerto de salida MIDI: " << status << std::endl;
        return false;
    }
    
    // Encontrar destinos MIDI
    numDestinations = MIDIGetNumberOfDestinations();
    std::cout << "[Maschine] Destinos MIDI encontrados: " << numDestinations << std::endl;
    
    for (int i = 0; i < numDestinations && i < 10; ++i) {
        midiDestinations[i] = MIDIGetDestination(i);
        CFStringRef name;
        MIDIObjectGetStringProperty(midiDestinations[i], kMIDIPropertyName, &name);
        char nameStr[256];
        CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
        std::cout << "[Maschine] Destino " << i << ": " << nameStr << std::endl;
        CFRelease(name);
    }
    
    return true;
}

bool MaschineMikroDriverUser::connectDevice() {
    std::cout << "[Maschine] Conectando dispositivo Maschine Mikro..." << std::endl;
    
    // Buscar dispositivo Maschine Mikro usando la misma lógica que Rebellion
    ItemCount numSources = MIDIGetNumberOfSources();
    std::cout << "[Maschine] Fuentes MIDI encontradas: " << numSources << std::endl;
    
    for (ItemCount i = 0; i < numSources; ++i) {
        MIDIEndpointRef source = MIDIGetSource(i);
        CFStringRef name;
        MIDIObjectGetStringProperty(source, kMIDIPropertyName, &name);
        char nameStr[256];
        CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
        
        std::cout << "[Maschine] Dispositivo encontrado: " << nameStr << std::endl;
        
        // Buscar específicamente "Maschine Mikro Input"
        if (strstr(nameStr, "Maschine Mikro Input")) {
            std::cout << "[Maschine] ¡Maschine Mikro encontrada!" << std::endl;
            
            // Crear puerto de entrada MIDI
            OSStatus status = MIDIInputPortCreate(midiClient, CFSTR("Maschine Input"), 
                [](const MIDIPacketList *pktlist, void *readProcRefCon, void *srcConnRefCon) {
                    MaschineMikroDriverUser* driver = static_cast<MaschineMikroDriverUser*>(readProcRefCon);
                    driver->handleMIDIInput(pktlist);
                }, this, &midiInPort);
            
            if (status != noErr) {
                std::cout << "[Error] No se pudo crear puerto de entrada MIDI: " << status << std::endl;
                CFRelease(name);
                continue;
            }
            
            // Conectar fuente MIDI
            status = MIDIPortConnectSource(midiInPort, source, NULL);
            if (status != noErr) {
                std::cout << "[Error] No se pudo conectar fuente MIDI: " << status << std::endl;
                CFRelease(name);
                continue;
            }
            
            std::cout << "[Maschine] ✅ Conectado a: " << nameStr << std::endl;
            CFRelease(name);
            return true;
        }
        CFRelease(name);
    }
    
    std::cout << "[Warning] No se encontró dispositivo Maschine Mikro Input" << std::endl;
    std::cout << "[Maschine] Usando modo simulación para inputs" << std::endl;
    return true;
}

void MaschineMikroDriverUser::disconnectDevice() {
    std::cout << "[Maschine] Desconectando dispositivo..." << std::endl;
    
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
}

void MaschineMikroDriverUser::handleMIDIInput(const MIDIPacketList* packetList) {
    const MIDIPacket* packet = &packetList->packet[0];
    
    for (int i = 0; i < packetList->numPackets; ++i) {
        if (packet->length >= 3) {
            unsigned char status = packet->data[0];
            unsigned char data1 = packet->data[1];
            unsigned char data2 = packet->data[2];
            
            // Analizar protocolo propietario de Maschine Mikro MK1
            if (status == 0xF0) {
                // SysEx message - protocolo propietario
                handleMaschineSysEx(packet);
            } else if (status == 0x74) {
                // Mensaje de estado específico de MK1
                handleMaschineStatus(packet);
            } else if ((status & 0xF0) == 0x90) {
                // Note On - posible input de pad
                if (data2 > 0) {
                    if (data1 >= 36 && data1 <= 51) {
                        int pad = data1 - 36;
                        std::cout << "🥁 PAD " << pad << " presionado (velocity: " << (int)data2 << ")" << std::endl;
                        handlePadPress(pad, data2);
                    }
                }
            } else if ((status & 0xF0) == 0x80) {
                // Note Off - liberación de pad
                if (data1 >= 36 && data1 <= 51) {
                    int pad = data1 - 36;
                    std::cout << "🥁 PAD " << pad << " liberado" << std::endl;
                    handlePadRelease(pad);
                }
            } else if ((status & 0xF0) == 0xB0) {
                // Control Change - botones y encoders
                if (data1 >= 16 && data1 <= 23) {
                    int button = data1 - 16;
                    if (data2 > 0) {
                        std::cout << "🔘 BOTÓN " << button << " presionado (value: " << (int)data2 << ")" << std::endl;
                        handleButtonPress(button, data2);
                    } else {
                        std::cout << "🔘 BOTÓN " << button << " liberado" << std::endl;
                        handleButtonRelease(button);
                    }
                } else if (data1 >= 24 && data1 <= 25) {
                    int encoder = data1 - 24;
                    std::cout << "🎛️ ENCODER " << encoder << " girado (value: " << (int)data2 << ")" << std::endl;
                    handleEncoderTurn(encoder, data2);
                }
            } else {
                // Otros mensajes MIDI
                std::cout << "📥 MIDI: " << std::hex << (int)status << " " << (int)data1 << " " << (int)data2 << std::dec << std::endl;
            }
        }
        
        packet = MIDIPacketNext(packet);
    }
}

void MaschineMikroDriverUser::handleMaschineSysEx(const MIDIPacket* packet) {
    // Analizar SysEx específico de Maschine Mikro MK1
    if (packet->length >= 4) {
        unsigned char manufacturer = packet->data[1];
        unsigned char deviceId = packet->data[2];
        unsigned char command = packet->data[3];
        
        std::cout << "🎹 SysEx MK1: Manufacturer=" << std::hex << (int)manufacturer 
                  << " Device=" << (int)deviceId << " Command=" << (int)command << std::dec << std::endl;
        
        // Procesar comandos específicos de Maschine
        switch (command) {
            case 0x01: // Estado del dispositivo
                handleDeviceStatus(packet);
                break;
            case 0x02: // Configuración
                handleDeviceConfig(packet);
                break;
            case 0x03: // Input de pad
                handlePadInput(packet);
                break;
            case 0x04: // Input de botón
                handleButtonInput(packet);
                break;
            case 0x05: // Input de encoder
                handleEncoderInput(packet);
                break;
            default:
                std::cout << "🎹 SysEx desconocido: " << std::hex << (int)command << std::dec << std::endl;
                break;
        }
    }
}

void MaschineMikroDriverUser::handleMaschineStatus(const MIDIPacket* packet) {
    // Procesar mensajes de estado específicos de MK1
    if (packet->length >= 3) {
        unsigned char data1 = packet->data[1];
        unsigned char data2 = packet->data[2];
        
        std::cout << "🎹 Status MK1: " << std::hex << (int)data1 << " " << (int)data2 << std::dec << std::endl;
        
        // Interpretar estados específicos
        if (data1 == 0x10) {
            // Estado de botones
            handleButtonStatus(data2);
        } else if (data1 >= 0x01 && data1 <= 0x04) {
            // Estado de pads
            handlePadStatus(data1 - 1, data2);
        }
    }
}

void MaschineMikroDriverUser::handleDeviceStatus(const MIDIPacket* packet) {
    std::cout << "🎹 Estado del dispositivo recibido" << std::endl;
    // Actualizar estado interno del dispositivo
    deviceConnected = true;
}

void MaschineMikroDriverUser::handleDeviceConfig(const MIDIPacket* packet) {
    std::cout << "🎹 Configuración del dispositivo recibida" << std::endl;
    // Procesar configuración
}

void MaschineMikroDriverUser::handlePadInput(const MIDIPacket* packet) {
    if (packet->length >= 5) {
        int pad = packet->data[4];
        int velocity = (packet->length >= 6) ? packet->data[5] : 127;
        
        std::cout << "🥁 PAD " << pad << " (SysEx) - velocity: " << velocity << std::endl;
        handlePadPress(pad, velocity);
    }
}

void MaschineMikroDriverUser::handleButtonInput(const MIDIPacket* packet) {
    if (packet->length >= 5) {
        int button = packet->data[4];
        int value = (packet->length >= 6) ? packet->data[5] : 127;
        
        std::cout << "🔘 BOTÓN " << button << " (SysEx) - value: " << value << std::endl;
        if (value > 0) {
            handleButtonPress(button, value);
        } else {
            handleButtonRelease(button);
        }
    }
}

void MaschineMikroDriverUser::handleEncoderInput(const MIDIPacket* packet) {
    if (packet->length >= 5) {
        int encoder = packet->data[4];
        int value = (packet->length >= 6) ? packet->data[5] : 64;
        
        std::cout << "🎛️ ENCODER " << encoder << " (SysEx) - value: " << value << std::endl;
        handleEncoderTurn(encoder, value);
    }
}

void MaschineMikroDriverUser::handleButtonStatus(unsigned char status) {
    std::cout << "🔘 Estado de botones: " << std::hex << (int)status << std::dec << std::endl;
    // Procesar estado de botones
}

void MaschineMikroDriverUser::handlePadStatus(int pad, unsigned char status) {
    std::cout << "🥁 Estado de pad " << pad << ": " << std::hex << (int)status << std::dec << std::endl;
    // Procesar estado de pad
}

void MaschineMikroDriverUser::handlePadPress(int pad, int velocity) {
    std::cout << "🎹 PAD " << pad << " presionado en modo Maschine (velocity: " << velocity << ")" << std::endl;
    
    // Actualizar estado interno
    if (pad >= 0 && pad < NUM_PADS) {
        maschineState.padStates[pad] = true;
        maschineState.padVelocities[pad] = velocity;
    }
    
    // Lógica específica de Maschine
    switch (pad) {
        case 0: // Pad 0 - Group A
            std::cout << "🎹 Activando Group A" << std::endl;
            break;
        case 1: // Pad 1 - Group B
            std::cout << "🎹 Activando Group B" << std::endl;
            break;
        case 2: // Pad 2 - Group C
            std::cout << "🎹 Activando Group C" << std::endl;
            break;
        case 3: // Pad 3 - Group D
            std::cout << "🎹 Activando Group D" << std::endl;
            break;
        default:
            // Pads 4-15 son sonidos
            int sound = pad - 4;
            if (sound >= 0 && sound < NUM_SOUNDS) {
                std::cout << "🎹 Sonido " << sound << " activado" << std::endl;
                maschineState.currentSound = sound;
            }
            break;
    }
}

void MaschineMikroDriverUser::handlePadRelease(int pad) {
    std::cout << "🎹 PAD " << pad << " liberado en modo Maschine" << std::endl;
    
    // Actualizar estado interno
    if (pad >= 0 && pad < NUM_PADS) {
        maschineState.padStates[pad] = false;
        maschineState.padVelocities[pad] = 0;
    }
}

void MaschineMikroDriverUser::handleButtonPress(int button, int value) {
    std::cout << "🎹 BOTÓN " << button << " presionado en modo Maschine (value: " << value << ")" << std::endl;
    
    // Actualizar estado interno
    if (button >= 0 && button < NUM_BUTTONS) {
        maschineState.buttonStates[button] = true;
    }
    
    // Lógica específica de Maschine
    switch (button) {
        case 0: // Shift
            std::cout << "🎹 Shift activado" << std::endl;
            maschineState.shiftPressed = true;
            break;
        case 1: // Select
            std::cout << "🎹 Select activado" << std::endl;
            break;
        case 2: // Solo
            std::cout << "🎹 Solo activado" << std::endl;
            break;
        case 3: // Mute
            std::cout << "🎹 Mute activado" << std::endl;
            break;
        case 4: // Play
            std::cout << "🎹 Play activado" << std::endl;
            maschineState.isPlaying = !maschineState.isPlaying;
            break;
        case 5: // Record
            std::cout << "🎹 Record activado" << std::endl;
            maschineState.isRecording = !maschineState.isRecording;
            break;
        case 6: // Erase
            std::cout << "🎹 Erase activado" << std::endl;
            break;
        case 7: // Automation
            std::cout << "🎹 Automation activado" << std::endl;
            break;
    }
}

void MaschineMikroDriverUser::handleButtonRelease(int button) {
    std::cout << "🎹 BOTÓN " << button << " liberado en modo Maschine" << std::endl;
    
    // Actualizar estado interno
    if (button >= 0 && button < NUM_BUTTONS) {
        maschineState.buttonStates[button] = false;
    }
    
    // Lógica específica de Maschine
    switch (button) {
        case 0: // Shift
            std::cout << "🎹 Shift desactivado" << std::endl;
            maschineState.shiftPressed = false;
            break;
    }
}

void MaschineMikroDriverUser::handleEncoderTurn(int encoder, int value) {
    std::cout << "🎹 ENCODER " << encoder << " girado en modo Maschine (value: " << value << ")" << std::endl;
    
    // Lógica específica de Maschine
    switch (encoder) {
        case 0: // Tempo
            {
                int delta = (value > 64) ? 1 : -1;
                maschineState.tempo += delta;
                if (maschineState.tempo < 60) maschineState.tempo = 60;
                if (maschineState.tempo > 200) maschineState.tempo = 200;
                std::cout << "🎹 Tempo ajustado a: " << maschineState.tempo << " BPM" << std::endl;
            }
            break;
        case 1: // Swing
            {
                int delta = (value > 64) ? 1 : -1;
                maschineState.swing += delta;
                if (maschineState.swing < 0) maschineState.swing = 0;
                if (maschineState.swing > 100) maschineState.swing = 100;
                std::cout << "🎹 Swing ajustado a: " << maschineState.swing << "%" << std::endl;
            }
            break;
    }
}

void MaschineMikroDriverUser::initializeMaschineState() {
    maschineState.currentMode = MASCHINE_MODE_NATIVE;
    maschineState.currentGroup = 0;
    maschineState.currentSound = 0;
    maschineState.currentPattern = 0;
    maschineState.currentScene = 0;
    maschineState.tempo = 120.0;
    maschineState.swing = 0.0;
    maschineState.isPlaying = false;
    maschineState.isRecording = false;
    maschineState.shiftPressed = false;
    maschineState.soloMode = false;
    maschineState.muteMode = false;
    maschineState.automationMode = false;
    // Inicializar LEDs y estados
    for (int i = 0; i < 16; ++i) maschineState.padLEDs[i] = false;
    for (int i = 0; i < 8; ++i) maschineState.buttonLEDs[i] = false;
    for (int i = 0; i < 2; ++i) maschineState.encoderLEDs[i] = 0;
}

// Handshake con el software Maschine (stub)
bool MaschineMikroDriverUser::connectMaschineSoftware() {
    std::cout << "[Maschine] Realizando handshake con el software Maschine..." << std::endl;
    // Aquí iría la lógica de handshake USB nativo
    maschineSoftwareConnected = true;
    return true;
}

void MaschineMikroDriverUser::disconnectMaschineSoftware() {
    std::cout << "[Maschine] Desconectando del software Maschine..." << std::endl;
    maschineSoftwareConnected = false;
}

bool MaschineMikroDriverUser::isMaschineSoftwareConnected() {
    return maschineSoftwareConnected;
}

void MaschineMikroDriverUser::sendToMaschineSoftware(const std::string& command) {
    std::cout << "[Maschine] Enviando comando al software Maschine: " << command << std::endl;
    // Aquí se enviaría el comando real por USB nativo
}

void MaschineMikroDriverUser::receiveFromMaschineSoftware() {
    std::cout << "[Maschine] Esperando mensajes del software Maschine..." << std::endl;
    // Aquí se recibirían mensajes reales
}

void MaschineMikroDriverUser::printMaschineStatus() {
    std::cout << "[Maschine] Estado actual:" << std::endl;
    std::cout << "  Modo: " << (maschineState.currentMode == MASCHINE_MODE_NATIVE ? "Maschine" : "MIDI") << std::endl;
    std::cout << "  Grupo: " << maschineState.currentGroup << std::endl;
    std::cout << "  Sonido: " << maschineState.currentSound << std::endl;
    std::cout << "  Patrón: " << maschineState.currentPattern << std::endl;
    std::cout << "  Escena: " << maschineState.currentScene << std::endl;
    std::cout << "  Tempo: " << maschineState.tempo << std::endl;
    std::cout << "  Swing: " << maschineState.swing << std::endl;
}

// Stub para mostrar menú Maschine
void MaschineMikroDriverUser::showMaschineMenu() {
    std::cout << "\n=== Menú Maschine Nativo ===" << std::endl;
    std::cout << "1. Handshake con software Maschine" << std::endl;
    std::cout << "2. Enviar comando de prueba" << std::endl;
    std::cout << "3. Mostrar estado Maschine" << std::endl;
    std::cout << "0. Salir" << std::endl;
    int choice;
    std::cin >> choice;
    switch (choice) {
        case 1:
            connectMaschineSoftware();
            break;
        case 2:
            sendToMaschineSoftware("test_command");
            break;
        case 3:
            printMaschineStatus();
            break;
        default:
            break;
    }
}

// === PADS EN MODO MASCHINE ===
void MaschineMikroDriverUser::handlePadPressMaschine(int pad, int velocity) {
    std::cout << "[Maschine] Pad " << pad << " presionado con velocidad " << velocity << std::endl;
    
    if (maschineState.shiftPressed) {
        // Modo Shift: seleccionar grupo/sonido/patrón
        if (pad < 16) {
            if (maschineState.currentMode == MASCHINE_MODE_NATIVE) {
                selectGroup(pad);
            }
        }
    } else {
        // Modo normal: reproducir sonido
        if (pad < 16) {
            selectSound(pad);
            // Enviar comando de reproducción al software Maschine
            sendToMaschineSoftware("pad_press:" + std::to_string(pad) + ":" + std::to_string(velocity));
        }
    }
    
    // Actualizar LED del pad
    setPadLED(pad, true);
}

void MaschineMikroDriverUser::handlePadReleaseMaschine(int pad) {
    std::cout << "[Maschine] Pad " << pad << " liberado" << std::endl;
    
    // Enviar comando de liberación al software Maschine
    sendToMaschineSoftware("pad_release:" + std::to_string(pad));
    
    // Apagar LED del pad
    setPadLED(pad, false);
}

void MaschineMikroDriverUser::handlePadLongPressMaschine(int pad) {
    std::cout << "[Maschine] Pad " << pad << " presionado largo" << std::endl;
    
    // Acción de presionado largo (ej: borrar, duplicar, etc.)
    sendToMaschineSoftware("pad_long_press:" + std::to_string(pad));
}

void MaschineMikroDriverUser::handlePadDoublePressMaschine(int pad) {
    std::cout << "[Maschine] Pad " << pad << " doble presionado" << std::endl;
    
    // Acción de doble presionado (ej: solo, mute, etc.)
    sendToMaschineSoftware("pad_double_press:" + std::to_string(pad));
}

// === BOTONES EN MODO MASCHINE ===
void MaschineMikroDriverUser::handleButtonPressMaschine(int button) {
    std::cout << "[Maschine] Botón " << button << " presionado" << std::endl;
    
    switch (button) {
        case BUTTON_SHIFT:
            maschineState.shiftPressed = true;
            setButtonLED(BUTTON_SHIFT, true);
            break;
        case BUTTON_SELECT:
            selectAll();
            break;
        case BUTTON_SOLO:
            toggleSoloMode();
            break;
        case BUTTON_MUTE:
            toggleMuteMode();
            break;
        case BUTTON_PLAY:
            startStopPlayback();
            break;
        case BUTTON_RECORD:
            startStopRecording();
            break;
        case BUTTON_ERASE:
            erasePattern();
            break;
        case BUTTON_AUTOMATION:
            toggleAutomationMode();
            break;
    }
    
    sendToMaschineSoftware("button_press:" + std::to_string(button));
}

void MaschineMikroDriverUser::handleButtonReleaseMaschine(int button) {
    std::cout << "[Maschine] Botón " << button << " liberado" << std::endl;
    
    if (button == BUTTON_SHIFT) {
        maschineState.shiftPressed = false;
        setButtonLED(BUTTON_SHIFT, false);
    }
    
    sendToMaschineSoftware("button_release:" + std::to_string(button));
}

void MaschineMikroDriverUser::handleButtonLongPressMaschine(int button) {
    std::cout << "[Maschine] Botón " << button << " presionado largo" << std::endl;
    sendToMaschineSoftware("button_long_press:" + std::to_string(button));
}

// === ENCODERS EN MODO MASCHINE ===
void MaschineMikroDriverUser::handleEncoderTurnMaschine(int encoder, int direction) {
    std::cout << "[Maschine] Encoder " << encoder << " girado dirección " << direction << std::endl;
    
    switch (encoder) {
        case ENCODER_TEMPO:
            changeTempo(maschineState.tempo + (direction * 1.0));
            break;
        case ENCODER_SWING:
            changeSwing(maschineState.swing + (direction * 0.1));
            break;
    }
    
    sendToMaschineSoftware("encoder_turn:" + std::to_string(encoder) + ":" + std::to_string(direction));
}

void MaschineMikroDriverUser::handleEncoderPressMaschine(int encoder) {
    std::cout << "[Maschine] Encoder " << encoder << " presionado" << std::endl;
    
    if (encoder == ENCODER_TEMPO) {
        tapTempo();
    }
    
    sendToMaschineSoftware("encoder_press:" + std::to_string(encoder));
}

// === CONTROL DE LEDS ===
void MaschineMikroDriverUser::setPadLED(int pad, bool state) {
    if (pad >= 0 && pad < 16) {
        maschineState.padLEDs[pad] = state;
        std::cout << "[Maschine] LED Pad " << pad << " " << (state ? "ON" : "OFF") << std::endl;
        
        // Comando SysEx específico de Maschine para LEDs
        // Basado en el protocolo de Rebellion
        std::vector<unsigned char> sysexData;
        sysexData.push_back(0xF0); // SysEx Start
        sysexData.push_back(0x00); // Manufacturer ID (NI)
        sysexData.push_back(0x20); // Manufacturer ID (NI)
        sysexData.push_back(0x3C); // Manufacturer ID (NI)
        sysexData.push_back(0x02); // Device ID (Maschine Mikro)
        sysexData.push_back(0x00); // Command: LED Control
        sysexData.push_back(0x00); // Subcommand: Pad LED
        sysexData.push_back(pad & 0x7F); // Pad number
        sysexData.push_back(state ? 0x7F : 0x00); // LED state
        sysexData.push_back(0xF7); // SysEx End
        
        // Enviar SysEx
        MIDIPacketList packetList;
        MIDIPacket* packet = MIDIPacketListInit(&packetList);
        
        packet = MIDIPacketListAdd(&packetList, sizeof(packetList), packet, 0, sysexData.size(), sysexData.data());
        
        // Enviar a todos los destinos MIDI
        for (int i = 0; i < numDestinations; ++i) {
            MIDISend(midiOutPort, midiDestinations[i], &packetList);
        }
        
        sendToMaschineSoftware("led_pad:" + std::to_string(pad) + ":" + std::to_string(state));
    }
}

void MaschineMikroDriverUser::setButtonLED(int button, bool state) {
    if (button >= 0 && button < 8) {
        maschineState.buttonLEDs[button] = state;
        std::cout << "[Maschine] LED Botón " << button << " " << (state ? "ON" : "OFF") << std::endl;
        
        // Comando SysEx específico de Maschine para LEDs de botones
        std::vector<unsigned char> sysexData;
        sysexData.push_back(0xF0); // SysEx Start
        sysexData.push_back(0x00); // Manufacturer ID (NI)
        sysexData.push_back(0x20); // Manufacturer ID (NI)
        sysexData.push_back(0x3C); // Manufacturer ID (NI)
        sysexData.push_back(0x02); // Device ID (Maschine Mikro)
        sysexData.push_back(0x00); // Command: LED Control
        sysexData.push_back(0x01); // Subcommand: Button LED
        sysexData.push_back(button & 0x7F); // Button number
        sysexData.push_back(state ? 0x7F : 0x00); // LED state
        sysexData.push_back(0xF7); // SysEx End
        
        // Enviar SysEx
        MIDIPacketList packetList;
        MIDIPacket* packet = MIDIPacketListInit(&packetList);
        
        packet = MIDIPacketListAdd(&packetList, sizeof(packetList), packet, 0, sysexData.size(), sysexData.data());
        
        // Enviar a todos los destinos MIDI
        for (int i = 0; i < numDestinations; ++i) {
            MIDISend(midiOutPort, midiDestinations[i], &packetList);
        }
        
        sendToMaschineSoftware("led_button:" + std::to_string(button) + ":" + std::to_string(state));
    }
}

void MaschineMikroDriverUser::setEncoderLED(int encoder, int value) {
    if (encoder >= 0 && encoder < 2) {
        maschineState.encoderLEDs[encoder] = value;
        std::cout << "[Maschine] LED Encoder " << encoder << " valor " << value << std::endl;
        sendToMaschineSoftware("led_encoder:" + std::to_string(encoder) + ":" + std::to_string(value));
    }
}

void MaschineMikroDriverUser::setAllPadLEDs(bool state) {
    for (int i = 0; i < 16; ++i) {
        setPadLED(i, state);
    }
}

void MaschineMikroDriverUser::setAllButtonLEDs(bool state) {
    for (int i = 0; i < 8; ++i) {
        setButtonLED(i, state);
    }
}

// === GESTIÓN DE GRUPOS ===
void MaschineMikroDriverUser::selectGroup(int group) {
    if (group >= 0 && group < MASCHINE_GROUPS) {
        maschineState.currentGroup = group;
        std::cout << "[Maschine] Grupo seleccionado: " << group << std::endl;
        
        // Actualizar LEDs de grupos
        setAllPadLEDs(false);
        setPadLED(group, true);
        
        sendToMaschineSoftware("select_group:" + std::to_string(group));
    }
}

void MaschineMikroDriverUser::createGroup(int group) {
    std::cout << "[Maschine] Creando grupo " << group << std::endl;
    maschineState.groupActive[group] = true;
    sendToMaschineSoftware("create_group:" + std::to_string(group));
}

void MaschineMikroDriverUser::deleteGroup(int group) {
    std::cout << "[Maschine] Eliminando grupo " << group << std::endl;
    maschineState.groupActive[group] = false;
    sendToMaschineSoftware("delete_group:" + std::to_string(group));
}

// === GESTIÓN DE SONIDOS ===
void MaschineMikroDriverUser::selectSound(int sound) {
    if (sound >= 0 && sound < MASCHINE_SOUNDS_PER_GROUP) {
        maschineState.currentSound = sound;
        std::cout << "[Maschine] Sonido seleccionado: " << sound << std::endl;
        sendToMaschineSoftware("select_sound:" + std::to_string(sound));
    }
}

void MaschineMikroDriverUser::createSound(int group, int sound) {
    std::cout << "[Maschine] Creando sonido " << sound << " en grupo " << group << std::endl;
    maschineState.soundActive[group][sound] = true;
    sendToMaschineSoftware("create_sound:" + std::to_string(group) + ":" + std::to_string(sound));
}

// === GESTIÓN DE PATRONES ===
void MaschineMikroDriverUser::selectPattern(int pattern) {
    if (pattern >= 0 && pattern < MASCHINE_PATTERNS_PER_GROUP) {
        maschineState.currentPattern = pattern;
        std::cout << "[Maschine] Patrón seleccionado: " << pattern << std::endl;
        sendToMaschineSoftware("select_pattern:" + std::to_string(pattern));
    }
}

void MaschineMikroDriverUser::createPattern(int group, int pattern) {
    std::cout << "[Maschine] Creando patrón " << pattern << " en grupo " << group << std::endl;
    maschineState.patternActive[group][pattern] = true;
    sendToMaschineSoftware("create_pattern:" + std::to_string(group) + ":" + std::to_string(pattern));
}

// === GESTIÓN DE ESCENAS ===
void MaschineMikroDriverUser::selectScene(int scene) {
    if (scene >= 0 && scene < MASCHINE_SCENES) {
        maschineState.currentScene = scene;
        std::cout << "[Maschine] Escena seleccionada: " << scene << std::endl;
        sendToMaschineSoftware("select_scene:" + std::to_string(scene));
    }
}

void MaschineMikroDriverUser::createScene(int scene) {
    std::cout << "[Maschine] Creando escena " << scene << std::endl;
    maschineState.sceneActive[scene] = true;
    sendToMaschineSoftware("create_scene:" + std::to_string(scene));
}

// === CONTROLES DE TRANSPORT ===
void MaschineMikroDriverUser::play() {
    maschineState.isPlaying = true;
    std::cout << "[Maschine] Reproduciendo..." << std::endl;
    setButtonLED(BUTTON_PLAY, true);
    sendToMaschineSoftware("play");
}

void MaschineMikroDriverUser::stop() {
    maschineState.isPlaying = false;
    std::cout << "[Maschine] Detenido" << std::endl;
    setButtonLED(BUTTON_PLAY, false);
    sendToMaschineSoftware("stop");
}

void MaschineMikroDriverUser::record() {
    maschineState.isRecording = true;
    std::cout << "[Maschine] Grabando..." << std::endl;
    setButtonLED(BUTTON_RECORD, true);
    sendToMaschineSoftware("record");
}

void MaschineMikroDriverUser::pause() {
    std::cout << "[Maschine] Pausado" << std::endl;
    sendToMaschineSoftware("pause");
}

void MaschineMikroDriverUser::startStopPlayback() {
    if (maschineState.isPlaying) {
        stop();
    } else {
        play();
    }
}

void MaschineMikroDriverUser::startStopRecording() {
    if (maschineState.isRecording) {
        maschineState.isRecording = false;
        setButtonLED(BUTTON_RECORD, false);
        sendToMaschineSoftware("stop_record");
    } else {
        record();
    }
}

// === TEMPO Y TIMING ===
void MaschineMikroDriverUser::setTempo(double bpm) {
    maschineState.tempo = bpm;
    std::cout << "[Maschine] Tempo: " << bpm << " BPM" << std::endl;
    sendToMaschineSoftware("set_tempo:" + std::to_string(bpm));
}

double MaschineMikroDriverUser::getTempo() {
    return maschineState.tempo;
}

void MaschineMikroDriverUser::setSwing(double swing) {
    maschineState.swing = swing;
    std::cout << "[Maschine] Swing: " << swing << std::endl;
    sendToMaschineSoftware("set_swing:" + std::to_string(swing));
}

double MaschineMikroDriverUser::getSwing() {
    return maschineState.swing;
}

void MaschineMikroDriverUser::tapTempo() {
    std::cout << "[Maschine] Tap tempo detectado" << std::endl;
    sendToMaschineSoftware("tap_tempo");
}

void MaschineMikroDriverUser::changeTempo(double newTempo) {
    if (newTempo >= 60.0 && newTempo <= 200.0) {
        setTempo(newTempo);
    }
}

void MaschineMikroDriverUser::changeSwing(double newSwing) {
    if (newSwing >= 0.0 && newSwing <= 1.0) {
        setSwing(newSwing);
    }
}

// === FUNCIONES ESPECIALES ===
void MaschineMikroDriverUser::toggleSoloMode() {
    maschineState.soloMode = !maschineState.soloMode;
    std::cout << "[Maschine] Solo mode: " << (maschineState.soloMode ? "ON" : "OFF") << std::endl;
    setButtonLED(BUTTON_SOLO, maschineState.soloMode);
    sendToMaschineSoftware("toggle_solo");
}

void MaschineMikroDriverUser::toggleMuteMode() {
    maschineState.muteMode = !maschineState.muteMode;
    std::cout << "[Maschine] Mute mode: " << (maschineState.muteMode ? "ON" : "OFF") << std::endl;
    setButtonLED(BUTTON_MUTE, maschineState.muteMode);
    sendToMaschineSoftware("toggle_mute");
}

void MaschineMikroDriverUser::toggleAutomationMode() {
    maschineState.automationMode = !maschineState.automationMode;
    std::cout << "[Maschine] Automation mode: " << (maschineState.automationMode ? "ON" : "OFF") << std::endl;
    setButtonLED(BUTTON_AUTOMATION, maschineState.automationMode);
    sendToMaschineSoftware("toggle_automation");
}

void MaschineMikroDriverUser::erasePattern() {
    std::cout << "[Maschine] Borrando patrón actual" << std::endl;
    sendToMaschineSoftware("erase_pattern");
}

void MaschineMikroDriverUser::selectAll() {
    std::cout << "[Maschine] Seleccionando todo" << std::endl;
    sendToMaschineSoftware("select_all");
}

// === MÉTODOS DE COMPATIBILIDAD MIDI ===
void MaschineMikroDriverUser::sendMIDINote(unsigned char note, unsigned char velocity, unsigned char channel) {
    std::cout << "[MIDI] Note: " << (int)note << " Velocity: " << (int)velocity << " Channel: " << (int)channel << std::endl;
}

void MaschineMikroDriverUser::sendMIDICC(unsigned char controller, unsigned char value, unsigned char channel) {
    std::cout << "[MIDI] CC: " << (int)controller << " Value: " << (int)value << " Channel: " << (int)channel << std::endl;
}

void MaschineMikroDriverUser::testAllPads() {
    std::cout << "[Test] Probando todos los pads..." << std::endl;
    for (int i = 0; i < 16; ++i) {
        handlePadPressMaschine(i, 127);
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        handlePadReleaseMaschine(i);
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
}

void MaschineMikroDriverUser::testAllButtons() {
    std::cout << "[Test] Probando todos los botones..." << std::endl;
    for (int i = 0; i < 8; ++i) {
        handleButtonPressMaschine(i);
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        handleButtonReleaseMaschine(i);
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
}

void MaschineMikroDriverUser::testAllEncoders() {
    std::cout << "[Test] Probando todos los encoders..." << std::endl;
    for (int i = 0; i < 2; ++i) {
        handleEncoderTurnMaschine(i, 1);
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        handleEncoderTurnMaschine(i, -1);
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
}

void MaschineMikroDriverUser::testIndividualPad(int pad) {
    if (pad >= 0 && pad < 16) {
        std::cout << "[Test] Probando pad " << pad << std::endl;
        handlePadPressMaschine(pad, 127);
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
        handlePadReleaseMaschine(pad);
    }
}

void MaschineMikroDriverUser::testIndividualButton(int button) {
    if (button >= 0 && button < 8) {
        std::cout << "[Test] Probando botón " << button << std::endl;
        handleButtonPressMaschine(button);
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
        handleButtonReleaseMaschine(button);
    }
}

void MaschineMikroDriverUser::testIndividualEncoder(int encoder) {
    if (encoder >= 0 && encoder < 2) {
        std::cout << "[Test] Probando encoder " << encoder << std::endl;
        handleEncoderTurnMaschine(encoder, 1);
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
        handleEncoderTurnMaschine(encoder, -1);
    }
}

void MaschineMikroDriverUser::runFullTestSuite() {
    std::cout << "[Test] Ejecutando suite completa de pruebas..." << std::endl;
    testAllPads();
    testAllButtons();
    testAllEncoders();
    std::cout << "[Test] Suite de pruebas completada" << std::endl;
}

// === MÉTODOS DE INFORMACIÓN ===
void MaschineMikroDriverUser::printDeviceInfo() {
    std::cout << "[Info] Dispositivo: Maschine Mikro" << std::endl;
    std::cout << "[Info] Vendor ID: 0x17cc" << std::endl;
    std::cout << "[Info] Product ID: 0x0815" << std::endl;
    std::cout << "[Info] Modo: Maschine Nativo" << std::endl;
}

void MaschineMikroDriverUser::printMIDIInfo() {
    std::cout << "[MIDI] Destinos MIDI disponibles: " << numDestinations << std::endl;
    for (int i = 0; i < numDestinations; ++i) {
        std::cout << "[MIDI] Destino " << i << ": " << "Maschine Mikro Output" << std::endl;
    }
}

void MaschineMikroDriverUser::printStatus() {
    printMaschineStatus();
}

// === MÉTODOS STUB PARA FUNCIONES AVANZADAS ===
void MaschineMikroDriverUser::initializeMaschine() {
    std::cout << "[Maschine] Inicializando modo Maschine..." << std::endl;
    connectMaschineSoftware();
}

void MaschineMikroDriverUser::setMaschineMode(int mode) {
    maschineState.currentMode = mode;
    std::cout << "[Maschine] Modo cambiado a: " << (mode == MASCHINE_MODE_NATIVE ? "Maschine" : "MIDI") << std::endl;
}

int MaschineMikroDriverUser::getMaschineMode() {
    return maschineState.currentMode;
}

void MaschineMikroDriverUser::runMaschineTestSuite() {
    std::cout << "[Maschine] Ejecutando suite de pruebas Maschine..." << std::endl;
    connectMaschineSoftware();
    testAllPads();
    testAllButtons();
    testAllEncoders();
    printMaschineStatus();
}

// Métodos stub para funciones no implementadas
void MaschineMikroDriverUser::launchMaschineSoftware() {}
void MaschineMikroDriverUser::newProject() {}
void MaschineMikroDriverUser::openProject(const std::string& path) {}
void MaschineMikroDriverUser::saveProject(const std::string& path) {}
void MaschineMikroDriverUser::exportProject(const std::string& path) {}
void MaschineMikroDriverUser::rewind() {}
void MaschineMikroDriverUser::fastForward() {}
void MaschineMikroDriverUser::enableAutomationMode() {}
void MaschineMikroDriverUser::disableAutomationMode() {}
void MaschineMikroDriverUser::recordAutomation(int parameter, double value) {}
void MaschineMikroDriverUser::playAutomation() {}
void MaschineMikroDriverUser::clearAutomation() {}
void MaschineMikroDriverUser::enableQuantizeMode() {}
void MaschineMikroDriverUser::disableQuantizeMode() {}
void MaschineMikroDriverUser::setQuantizeGrid(int grid) {}
void MaschineMikroDriverUser::setQuantizeStrength(double strength) {}
void MaschineMikroDriverUser::enableSwingMode() {}
void MaschineMikroDriverUser::disableSwingMode() {}
void MaschineMikroDriverUser::setSwingAmount(double amount) {}
void MaschineMikroDriverUser::setSwingGrid(int grid) {}
void MaschineMikroDriverUser::setDisplayText(const std::string& text) {}
void MaschineMikroDriverUser::clearDisplay() {}
void MaschineMikroDriverUser::setDisplayBrightness(int level) {}
void MaschineMikroDriverUser::flashPadLED(int pad, int duration) {}
void MaschineMikroDriverUser::flashButtonLED(int button, int duration) {}
void MaschineMikroDriverUser::pulsePadLED(int pad, int speed) {}
void MaschineMikroDriverUser::pulseButtonLED(int button, int speed) {}
void MaschineMikroDriverUser::renameGroup(int group, const std::string& name) {}
void MaschineMikroDriverUser::copyGroup(int fromGroup, int toGroup) {}
void MaschineMikroDriverUser::deleteSound(int group, int sound) {}
void MaschineMikroDriverUser::renameSound(int group, int sound, const std::string& name) {}
void MaschineMikroDriverUser::copySound(int fromGroup, int fromSound, int toGroup, int toSound) {}
void MaschineMikroDriverUser::deletePattern(int group, int pattern) {}
void MaschineMikroDriverUser::renamePattern(int group, int pattern, const std::string& name) {}
void MaschineMikroDriverUser::copyPattern(int fromGroup, int fromPattern, int toGroup, int toPattern) {}
void MaschineMikroDriverUser::deleteScene(int scene) {}
void MaschineMikroDriverUser::renameScene(int scene, const std::string& name) {}
void MaschineMikroDriverUser::copyScene(int fromScene, int toScene) {}

// Funciones para listar dispositivos MIDI
void MaschineMikroDriverUser::listMidiSources() {
    ItemCount numSources = MIDIGetNumberOfSources();
    std::cout << "📡 Fuentes MIDI disponibles (" << numSources << "):" << std::endl;
    
    for (ItemCount i = 0; i < numSources; ++i) {
        MIDIEndpointRef source = MIDIGetSource(i);
        CFStringRef name;
        MIDIObjectGetStringProperty(source, kMIDIPropertyName, &name);
        char nameStr[256];
        CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
        
        std::cout << "  " << i << ": " << nameStr << std::endl;
        CFRelease(name);
    }
}

void MaschineMikroDriverUser::listMidiDestinations() {
    ItemCount numDestinations = MIDIGetNumberOfDestinations();
    std::cout << "📡 Destinos MIDI disponibles (" << numDestinations << "):" << std::endl;
    
    for (ItemCount i = 0; i < numDestinations; ++i) {
        MIDIEndpointRef destination = MIDIGetDestination(i);
        CFStringRef name;
        MIDIObjectGetStringProperty(destination, kMIDIPropertyName, &name);
        char nameStr[256];
        CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
        
        std::cout << "  " << i << ": " << nameStr << std::endl;
        CFRelease(name);
    }
}
void MaschineMikroDriverUser::duplicatePattern() {}
void MaschineMikroDriverUser::clearPattern() {}
void MaschineMikroDriverUser::saveProject() {}
void MaschineMikroDriverUser::loadProject() {} 