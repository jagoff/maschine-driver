#include "MaschineMikroDriver_User.h"
#include <iostream>
#include <string>
#include <cstring>
#include <thread>
#include <chrono>

void showMainMenu() {
    std::cout << "\n🎹 === MASCHINE MIKRO DRIVER - MODO NATIVO ===" << std::endl;
    std::cout << "1.  Inicializar modo Maschine" << std::endl;
    std::cout << "2.  Conectar con software Maschine" << std::endl;
    std::cout << "3.  Mostrar estado Maschine" << std::endl;
    std::cout << "4.  Probar pads (modo Maschine)" << std::endl;
    std::cout << "5.  Probar botones (modo Maschine)" << std::endl;
    std::cout << "6.  Probar encoders (modo Maschine)" << std::endl;
    std::cout << "7.  Control de grupos" << std::endl;
    std::cout << "8.  Control de sonidos" << std::endl;
    std::cout << "9.  Control de patrones" << std::endl;
    std::cout << "10. Control de escenas" << std::endl;
    std::cout << "11. Control de transport" << std::endl;
    std::cout << "12. Control de tempo y swing" << std::endl;
    std::cout << "13. Control de LEDs" << std::endl;
    std::cout << "14. Suite completa de pruebas Maschine" << std::endl;
    std::cout << "15. Modo MIDI (compatibilidad)" << std::endl;
    std::cout << "0.  Salir" << std::endl;
    std::cout << "Selecciona una opción: ";
}

void showGroupMenu() {
    std::cout << "\n=== CONTROL DE GRUPOS ===" << std::endl;
    std::cout << "1. Seleccionar grupo" << std::endl;
    std::cout << "2. Crear grupo" << std::endl;
    std::cout << "3. Eliminar grupo" << std::endl;
    std::cout << "0. Volver" << std::endl;
}

void showSoundMenu() {
    std::cout << "\n=== CONTROL DE SONIDOS ===" << std::endl;
    std::cout << "1. Seleccionar sonido" << std::endl;
    std::cout << "2. Crear sonido" << std::endl;
    std::cout << "0. Volver" << std::endl;
}

void showPatternMenu() {
    std::cout << "\n=== CONTROL DE PATRONES ===" << std::endl;
    std::cout << "1. Seleccionar patrón" << std::endl;
    std::cout << "2. Crear patrón" << std::endl;
    std::cout << "3. Borrar patrón" << std::endl;
    std::cout << "0. Volver" << std::endl;
}

void showSceneMenu() {
    std::cout << "\n=== CONTROL DE ESCENAS ===" << std::endl;
    std::cout << "1. Seleccionar escena" << std::endl;
    std::cout << "2. Crear escena" << std::endl;
    std::cout << "0. Volver" << std::endl;
}

void showTransportMenu() {
    std::cout << "\n=== CONTROL DE TRANSPORT ===" << std::endl;
    std::cout << "1. Play/Stop" << std::endl;
    std::cout << "2. Record" << std::endl;
    std::cout << "3. Pause" << std::endl;
    std::cout << "4. Solo Mode" << std::endl;
    std::cout << "5. Mute Mode" << std::endl;
    std::cout << "6. Automation Mode" << std::endl;
    std::cout << "0. Volver" << std::endl;
}

void showTempoMenu() {
    std::cout << "\n=== CONTROL DE TEMPO Y SWING ===" << std::endl;
    std::cout << "1. Cambiar tempo" << std::endl;
    std::cout << "2. Cambiar swing" << std::endl;
    std::cout << "3. Tap tempo" << std::endl;
    std::cout << "4. Mostrar tempo actual" << std::endl;
    std::cout << "0. Volver" << std::endl;
}

void showLEDMenu() {
    std::cout << "\n=== CONTROL DE LEDS ===" << std::endl;
    std::cout << "1. Encender todos los pads" << std::endl;
    std::cout << "2. Apagar todos los pads" << std::endl;
    std::cout << "3. Encender todos los botones" << std::endl;
    std::cout << "4. Apagar todos los botones" << std::endl;
    std::cout << "5. Controlar LED individual" << std::endl;
    std::cout << "0. Volver" << std::endl;
}

void showHelp() {
    std::cout << "🎹 Maschine Mikro Driver - Modo Nativo" << std::endl;
    std::cout << "Uso: maschine_driver [OPCIÓN]" << std::endl;
    std::cout << "" << std::endl;
    std::cout << "Opciones:" << std::endl;
    std::cout << "  --help, -h           Mostrar esta ayuda" << std::endl;
    std::cout << "  --debug, -d          Modo debug interactivo" << std::endl;
    std::cout << "  --list-sources       Listar fuentes MIDI" << std::endl;
    std::cout << "  --list-destinations  Listar destinos MIDI" << std::endl;
    std::cout << "  --test-connection    Probar conexión" << std::endl;
    std::cout << "  --maschine-mode      Iniciar modo Maschine" << std::endl;
    std::cout << "  --midi-mode          Iniciar modo MIDI" << std::endl;
    std::cout << "" << std::endl;
    std::cout << "Sin argumentos: Modo interactivo completo" << std::endl;
}

void listMidiSources() {
    MaschineMikroDriverUser driver;
    if (driver.initialize()) {
        std::cout << "🎵 Fuentes MIDI disponibles:" << std::endl;
        driver.listMidiSources();
    } else {
        std::cout << "❌ Error inicializando driver" << std::endl;
    }
}

void listMidiDestinations() {
    MaschineMikroDriverUser driver;
    if (driver.initialize()) {
        std::cout << "🎵 Destinos MIDI disponibles:" << std::endl;
        driver.listMidiDestinations();
    } else {
        std::cout << "❌ Error inicializando driver" << std::endl;
    }
}

void testConnection() {
    MaschineMikroDriverUser driver;
    
    std::cout << "🔍 Probando conexión..." << std::endl;
    
    if (!driver.initialize()) {
        std::cout << "❌ Error al inicializar el driver" << std::endl;
        return;
    }
    
    if (!driver.connectDevice()) {
        std::cout << "❌ Error al conectar el dispositivo" << std::endl;
        return;
    }
    
    std::cout << "✅ Conexión exitosa" << std::endl;
    std::cout << "📊 Estado del dispositivo:" << std::endl;
    driver.printMaschineStatus();
}

void debugMode() {
    MaschineMikroDriverUser driver;
    
    std::cout << "🐛 Iniciando modo debug..." << std::endl;
    
    if (!driver.initialize()) {
        std::cout << "❌ Error al inicializar el driver" << std::endl;
        return;
    }
    
    if (!driver.connectDevice()) {
        std::cout << "❌ Error al conectar el dispositivo" << std::endl;
        return;
    }
    
    std::cout << "✅ Driver inicializado y dispositivo conectado" << std::endl;
    std::cout << "🎯 Modo debug activo - Presiona Ctrl+C para salir" << std::endl;
    
    // Loop de debug
    while (true) {
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        // El driver maneja los inputs automáticamente
    }
}

void maschineMode() {
    MaschineMikroDriverUser driver;
    
    std::cout << "🎹 Iniciando modo Maschine..." << std::endl;
    
    if (!driver.initialize()) {
        std::cout << "❌ Error al inicializar el driver" << std::endl;
        return;
    }
    
    if (!driver.connectDevice()) {
        std::cout << "❌ Error al conectar el dispositivo" << std::endl;
        return;
    }
    
    driver.initializeMaschine();
    std::cout << "✅ Modo Maschine activado" << std::endl;
    
    // Loop del modo Maschine
    while (true) {
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        // El driver maneja la lógica de Maschine automáticamente
    }
}

void midiMode() {
    MaschineMikroDriverUser driver;
    
    std::cout << "🎵 Iniciando modo MIDI..." << std::endl;
    
    if (!driver.initialize()) {
        std::cout << "❌ Error al inicializar el driver" << std::endl;
        return;
    }
    
    if (!driver.connectDevice()) {
        std::cout << "❌ Error al conectar el dispositivo" << std::endl;
        return;
    }
    
    std::cout << "✅ Modo MIDI activado" << std::endl;
    
    // Loop del modo MIDI
    while (true) {
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        // El driver maneja los mensajes MIDI automáticamente
    }
}

int main(int argc, char* argv[]) {
    // Procesar argumentos de línea de comandos
    if (argc > 1) {
        if (strcmp(argv[1], "--help") == 0 || strcmp(argv[1], "-h") == 0) {
            showHelp();
            return 0;
        } else if (strcmp(argv[1], "--debug") == 0 || strcmp(argv[1], "-d") == 0) {
            debugMode();
            return 0;
        } else if (strcmp(argv[1], "--list-sources") == 0) {
            listMidiSources();
            return 0;
        } else if (strcmp(argv[1], "--list-destinations") == 0) {
            listMidiDestinations();
            return 0;
        } else if (strcmp(argv[1], "--test-connection") == 0) {
            testConnection();
            return 0;
        } else if (strcmp(argv[1], "--maschine-mode") == 0) {
            maschineMode();
            return 0;
        } else if (strcmp(argv[1], "--midi-mode") == 0) {
            midiMode();
            return 0;
        } else {
            std::cout << "❌ Opción desconocida: " << argv[1] << std::endl;
            showHelp();
            return 1;
        }
    }
    
    // Modo interactivo (sin argumentos)
    MaschineMikroDriverUser driver;
    
    std::cout << "🎹 Iniciando Maschine Mikro Driver en modo nativo..." << std::endl;
    
    if (!driver.initialize()) {
        std::cout << "❌ Error al inicializar el driver" << std::endl;
        return 1;
    }
    
    if (!driver.connectDevice()) {
        std::cout << "❌ Error al conectar el dispositivo" << std::endl;
        return 1;
    }
    
    std::cout << "✅ Driver inicializado y dispositivo conectado" << std::endl;
    
    int choice;
    do {
        showMainMenu();
        std::cin >> choice;
        
        switch (choice) {
            case 1: {
                std::cout << "🎹 Inicializando modo Maschine..." << std::endl;
                driver.initializeMaschine();
                break;
            }
            case 2: {
                std::cout << "🔗 Conectando con software Maschine..." << std::endl;
                if (driver.connectMaschineSoftware()) {
                    std::cout << "✅ Conectado al software Maschine" << std::endl;
                } else {
                    std::cout << "❌ Error al conectar con el software Maschine" << std::endl;
                }
                break;
            }
            case 3: {
                driver.printMaschineStatus();
                break;
            }
            case 4: {
                std::cout << "🎯 Probando pads en modo Maschine..." << std::endl;
                driver.testAllPads();
                break;
            }
            case 5: {
                std::cout << "🔘 Probando botones en modo Maschine..." << std::endl;
                driver.testAllButtons();
                break;
            }
            case 6: {
                std::cout << "🎛️ Probando encoders en modo Maschine..." << std::endl;
                driver.testAllEncoders();
                break;
            }
            case 7: {
                int groupChoice;
                do {
                    showGroupMenu();
                    std::cin >> groupChoice;
                    
                    switch (groupChoice) {
                        case 1: {
                            int group;
                            std::cout << "Ingresa el número de grupo (0-15): ";
                            std::cin >> group;
                            driver.selectGroup(group);
                            break;
                        }
                        case 2: {
                            int group;
                            std::cout << "Ingresa el número de grupo a crear (0-15): ";
                            std::cin >> group;
                            driver.createGroup(group);
                            break;
                        }
                        case 3: {
                            int group;
                            std::cout << "Ingresa el número de grupo a eliminar (0-15): ";
                            std::cin >> group;
                            driver.deleteGroup(group);
                            break;
                        }
                    }
                } while (groupChoice != 0);
                break;
            }
            case 8: {
                int soundChoice;
                do {
                    showSoundMenu();
                    std::cin >> soundChoice;
                    
                    switch (soundChoice) {
                        case 1: {
                            int sound;
                            std::cout << "Ingresa el número de sonido (0-15): ";
                            std::cin >> sound;
                            driver.selectSound(sound);
                            break;
                        }
                        case 2: {
                            int group, sound;
                            std::cout << "Ingresa el grupo (0-15): ";
                            std::cin >> group;
                            std::cout << "Ingresa el número de sonido (0-15): ";
                            std::cin >> sound;
                            driver.createSound(group, sound);
                            break;
                        }
                    }
                } while (soundChoice != 0);
                break;
            }
            case 9: {
                int patternChoice;
                do {
                    showPatternMenu();
                    std::cin >> patternChoice;
                    
                    switch (patternChoice) {
                        case 1: {
                            int pattern;
                            std::cout << "Ingresa el número de patrón (0-15): ";
                            std::cin >> pattern;
                            driver.selectPattern(pattern);
                            break;
                        }
                        case 2: {
                            int group, pattern;
                            std::cout << "Ingresa el grupo (0-15): ";
                            std::cin >> group;
                            std::cout << "Ingresa el número de patrón (0-15): ";
                            std::cin >> pattern;
                            driver.createPattern(group, pattern);
                            break;
                        }
                        case 3: {
                            driver.erasePattern();
                            break;
                        }
                    }
                } while (patternChoice != 0);
                break;
            }
            case 10: {
                int sceneChoice;
                do {
                    showSceneMenu();
                    std::cin >> sceneChoice;
                    
                    switch (sceneChoice) {
                        case 1: {
                            int scene;
                            std::cout << "Ingresa el número de escena (0-15): ";
                            std::cin >> scene;
                            driver.selectScene(scene);
                            break;
                        }
                        case 2: {
                            int scene;
                            std::cout << "Ingresa el número de escena a crear (0-15): ";
                            std::cin >> scene;
                            driver.createScene(scene);
                            break;
                        }
                    }
                } while (sceneChoice != 0);
                break;
            }
            case 11: {
                int transportChoice;
                do {
                    showTransportMenu();
                    std::cin >> transportChoice;
                    
                    switch (transportChoice) {
                        case 1:
                            driver.startStopPlayback();
                            break;
                        case 2:
                            driver.startStopRecording();
                            break;
                        case 3:
                            driver.pause();
                            break;
                        case 4:
                            driver.toggleSoloMode();
                            break;
                        case 5:
                            driver.toggleMuteMode();
                            break;
                        case 6:
                            driver.toggleAutomationMode();
                            break;
                    }
                } while (transportChoice != 0);
                break;
            }
            case 12: {
                int tempoChoice;
                do {
                    showTempoMenu();
                    std::cin >> tempoChoice;
                    
                    switch (tempoChoice) {
                        case 1: {
                            double tempo;
                            std::cout << "Ingresa el nuevo tempo (60-200 BPM): ";
                            std::cin >> tempo;
                            driver.setTempo(tempo);
                            break;
                        }
                        case 2: {
                            double swing;
                            std::cout << "Ingresa el nuevo swing (0.0-1.0): ";
                            std::cin >> swing;
                            driver.setSwing(swing);
                            break;
                        }
                        case 3:
                            driver.tapTempo();
                            break;
                        case 4:
                            std::cout << "Tempo actual: " << driver.getTempo() << " BPM" << std::endl;
                            std::cout << "Swing actual: " << driver.getSwing() << std::endl;
                            break;
                    }
                } while (tempoChoice != 0);
                break;
            }
            case 13: {
                int ledChoice;
                do {
                    showLEDMenu();
                    std::cin >> ledChoice;
                    
                    switch (ledChoice) {
                        case 1:
                            driver.setAllPadLEDs(true);
                            break;
                        case 2:
                            driver.setAllPadLEDs(false);
                            break;
                        case 3:
                            driver.setAllButtonLEDs(true);
                            break;
                        case 4:
                            driver.setAllButtonLEDs(false);
                            break;
                        case 5: {
                            std::string type;
                            int index;
                            std::cout << "Tipo (pad/button/encoder): ";
                            std::cin >> type;
                            std::cout << "Índice (0-15 para pads, 0-7 para botones, 0-1 para encoders): ";
                            std::cin >> index;
                            
                            if (type == "pad") {
                                driver.setPadLED(index, true);
                            } else if (type == "button") {
                                driver.setButtonLED(index, true);
                            } else if (type == "encoder") {
                                driver.setEncoderLED(index, 127);
                            }
                            break;
                        }
                    }
                } while (ledChoice != 0);
                break;
            }
            case 14: {
                std::cout << "🧪 Ejecutando suite completa de pruebas Maschine..." << std::endl;
                driver.runMaschineTestSuite();
                break;
            }
            case 15: {
                std::cout << "🎵 Cambiando a modo MIDI..." << std::endl;
                driver.setMaschineMode(MASCHINE_MODE_MIDI);
                driver.runFullTestSuite();
                break;
            }
            case 0:
                std::cout << "👋 ¡Hasta luego!" << std::endl;
                break;
            default:
                std::cout << "❌ Opción inválida" << std::endl;
                break;
        }
        
    } while (choice != 0);
    
    return 0;
} 