#ifndef MASCHINE_MIKRO_DRIVER_USER_H
#define MASCHINE_MIKRO_DRIVER_USER_H

#include <iostream>
#include <vector>
#include <string>
#include <map>
#include <CoreMIDI/CoreMIDI.h>
#include <CoreFoundation/CoreFoundation.h>

// Constantes para Maschine Mikro MK1
#define NUM_PADS 16
#define NUM_BUTTONS 8
#define NUM_SOUNDS 12

// Maschine Mode Constants
#define MASCHINE_MODE_NATIVE 0
#define MASCHINE_MODE_MIDI   1

// Maschine Pad Functions
#define PAD_FUNCTION_GROUP    0
#define PAD_FUNCTION_SOUND    1
#define PAD_FUNCTION_PATTERN  2
#define PAD_FUNCTION_SCENE    3

// Maschine Button Functions
#define BUTTON_SHIFT          0
#define BUTTON_SELECT         1
#define BUTTON_SOLO           2
#define BUTTON_MUTE           3
#define BUTTON_PLAY           4
#define BUTTON_RECORD         5
#define BUTTON_ERASE          6
#define BUTTON_AUTOMATION     7

// Maschine Encoder Functions
#define ENCODER_TEMPO         0
#define ENCODER_SWING         1

// Maschine Groups (16 groups)
#define MASCHINE_GROUPS       16
#define MASCHINE_SOUNDS_PER_GROUP 16
#define MASCHINE_PATTERNS_PER_GROUP 16
#define MASCHINE_SCENES       16

// Maschine States
struct MaschineState {
    int currentMode;
    int currentGroup;
    int currentSound;
    int currentPattern;
    int currentScene;
    int tempo;
    int swing;
    bool isPlaying;
    bool isRecording;
    bool shiftPressed;
    bool soloMode;
    bool muteMode;
    bool automationMode;
    bool padStates[16];
    int padVelocities[16];
    bool buttonStates[8];
    
    // LED states
    bool padLEDs[16];
    bool buttonLEDs[8];
    int encoderLEDs[2];
    
    // Group states
    bool groupActive[MASCHINE_GROUPS];
    bool soundActive[MASCHINE_GROUPS][MASCHINE_SOUNDS_PER_GROUP];
    bool patternActive[MASCHINE_GROUPS][MASCHINE_PATTERNS_PER_GROUP];
    bool sceneActive[MASCHINE_SCENES];
};

class MaschineMikroDriverUser {
private:
    MIDIClientRef midiClient;
    MIDIPortRef midiOutPort;
    MIDIEndpointRef midiDestinations[10];
    int numDestinations;
    bool deviceConnected;
    
    // Maschine specific
    MaschineState maschineState;
    std::map<int, std::string> groupNames;
    std::map<int, std::string> soundNames;
    std::map<int, std::string> patternNames;
    std::map<int, std::string> sceneNames;
    
    // Maschine software communication
    bool maschineSoftwareConnected;
    std::string maschineSoftwarePath;
    
    // MIDI communication
    MIDIPortRef midiInPort;
    void handleMIDIInput(const MIDIPacketList* packetList);
    
    // Internal methods
    void initializeMaschineState();
    void setupGroupNames();
    void setupSoundNames();
    void setupPatternNames();
    void setupSceneNames();
    void updateLEDs();
    void sendMaschineCommand(int command, int value);
    void handleMaschineMode();
    void handleMIDIMode();
    void switchMode(int newMode);
    void updateGroup(int group);
    void updateSound(int sound);
    void updatePattern(int pattern);
    void updateScene(int scene);
    void changeTempo(double newTempo);
    void changeSwing(double newSwing);
    void duplicatePattern();
    void clearPattern();
    void saveProject();
    void loadProject();
    
    // Métodos de manejo de protocolo Maschine MK1
    void handleMaschineSysEx(const MIDIPacket* packet);
    void handleMaschineStatus(const MIDIPacket* packet);
    void handleDeviceStatus(const MIDIPacket* packet);
    void handleDeviceConfig(const MIDIPacket* packet);
    void handlePadInput(const MIDIPacket* packet);
    void handleButtonInput(const MIDIPacket* packet);
    void handleEncoderInput(const MIDIPacket* packet);
    void handleButtonStatus(unsigned char status);
    void handlePadStatus(int pad, unsigned char status);
    
    // Métodos de manejo de inputs
    void handlePadPress(int pad, int velocity);
    void handlePadRelease(int pad);
    void handleButtonPress(int button, int value);
    void handleButtonRelease(int button);
    void handleEncoderTurn(int encoder, int value);
    
public:
    MaschineMikroDriverUser();
    ~MaschineMikroDriverUser();
    
    // Core functionality
    bool initialize();
    bool connectDevice();
    void disconnectDevice();
    void printDeviceInfo();
    void printMIDIInfo();
    void printStatus();
    
    // Maschine specific methods
    void initializeMaschine();
    void setMaschineMode(int mode);
    int getMaschineMode();
    void printMaschineStatus();
    void showMaschineMenu();
    void runMaschineTestSuite();
    
    // Pad handling in Maschine mode
    void handlePadPressMaschine(int pad, int velocity);
    void handlePadReleaseMaschine(int pad);
    void handlePadLongPressMaschine(int pad);
    void handlePadDoublePressMaschine(int pad);
    
    // Button handling in Maschine mode
    void handleButtonPressMaschine(int button);
    void handleButtonReleaseMaschine(int button);
    void handleButtonLongPressMaschine(int button);
    
    // Encoder handling in Maschine mode
    void handleEncoderTurnMaschine(int encoder, int direction);
    void handleEncoderPressMaschine(int encoder);
    
    // Group management
    void selectGroup(int group);
    void createGroup(int group);
    void deleteGroup(int group);
    void renameGroup(int group, const std::string& name);
    void copyGroup(int fromGroup, int toGroup);
    
    // Sound management
    void selectSound(int sound);
    void createSound(int group, int sound);
    void deleteSound(int group, int sound);
    void renameSound(int group, int sound, const std::string& name);
    void copySound(int fromGroup, int fromSound, int toGroup, int toSound);
    
    // Pattern management
    void selectPattern(int pattern);
    void createPattern(int group, int pattern);
    void deletePattern(int group, int pattern);
    void renamePattern(int group, int pattern, const std::string& name);
    void copyPattern(int fromGroup, int fromPattern, int toGroup, int toPattern);
    
    // Scene management
    void selectScene(int scene);
    void createScene(int scene);
    void deleteScene(int scene);
    void renameScene(int scene, const std::string& name);
    void copyScene(int fromScene, int toScene);
    
    // Transport controls
    void play();
    void stop();
    void record();
    void pause();
    void rewind();
    void fastForward();
    
    // Tempo and timing
    void setTempo(double bpm);
    double getTempo();
    void setSwing(double swing);
    double getSwing();
    void tapTempo();
    
    // Project management
    void newProject();
    void openProject(const std::string& path);
    void saveProject(const std::string& path);
    void exportProject(const std::string& path);
    
    // Legacy MIDI methods (for compatibility)
    void sendMIDINote(unsigned char note, unsigned char velocity, unsigned char channel);
    void sendMIDICC(unsigned char controller, unsigned char value, unsigned char channel);
    void testAllPads();
    void testAllButtons();
    void testAllEncoders();
    void testIndividualPad(int pad);
    void testIndividualButton(int button);
    void testIndividualEncoder(int encoder);
    void runFullTestSuite();
    
    // Maschine software integration
    bool connectMaschineSoftware();
    void disconnectMaschineSoftware();
    bool isMaschineSoftwareConnected();
    void launchMaschineSoftware();
    void sendToMaschineSoftware(const std::string& command);
    void receiveFromMaschineSoftware();
    
    // LED control
    void setPadLED(int pad, bool state);
    void setButtonLED(int button, bool state);
    void setEncoderLED(int encoder, int value);
    void setAllPadLEDs(bool state);
    void setAllButtonLEDs(bool state);
    void flashPadLED(int pad, int duration);
    void flashButtonLED(int button, int duration);
    void pulsePadLED(int pad, int speed);
    void pulseButtonLED(int button, int speed);
    
    // Display control (if available)
    void setDisplayText(const std::string& text);
    void clearDisplay();
    void setDisplayBrightness(int level);
    
    // Advanced features
    void enableAutomationMode();
    void disableAutomationMode();
    void recordAutomation(int parameter, double value);
    void playAutomation();
    void clearAutomation();
    
    void enableQuantizeMode();
    void disableQuantizeMode();
    void setQuantizeGrid(int grid);
    void setQuantizeStrength(double strength);
    
    void enableSwingMode();
    void disableSwingMode();
    void setSwingAmount(double amount);
    void setSwingGrid(int grid);
    
    // Public control methods
    void toggleSoloMode();
    void toggleMuteMode();
    void toggleAutomationMode();
    void startStopPlayback();
    void startStopRecording();
    void erasePattern();
    void selectAll();
    
    // Funciones adicionales para argumentos de línea de comandos
    void listMidiSources();
    void listMidiDestinations();
};

#endif // MASCHINE_MIKRO_DRIVER_USER_H 