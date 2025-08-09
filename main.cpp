#include "MaschineMikroDriver_User.h"
#include <iostream>
#include <thread>
#include <chrono>
#include <signal.h>

MaschineMikroDriverUser* driver = nullptr;

void signalHandler(int signum) {
    std::cout << "\n🛑 Señal de interrupción recibida. Cerrando driver..." << std::endl;
    if (driver) {
        delete driver;
    }
    exit(signum);
}

int main() {
    std::cout << "🎹 =========================================" << std::endl;
    std::cout << "🎹 MASCHINE MIKRO DRIVER - INICIANDO" << std::endl;
    std::cout << "🎹 =========================================" << std::endl;
    std::cout << "" << std::endl;
    
    // Configurar manejador de señales
    signal(SIGINT, signalHandler);
    signal(SIGTERM, signalHandler);
    
    try {
        // Crear instancia del driver
        driver = new MaschineMikroDriverUser();
        
        // Inicializar driver
        if (!driver->initialize()) {
            std::cout << "❌ Error inicializando driver" << std::endl;
            delete driver;
            return 1;
        }
        
        std::cout << "✅ Driver inicializado correctamente" << std::endl;
        
        // Conectar dispositivo
        if (!driver->connectDevice()) {
            std::cout << "❌ Error conectando dispositivo" << std::endl;
            delete driver;
            return 1;
        }
        
        std::cout << "✅ Dispositivo conectado" << std::endl;
        std::cout << "" << std::endl;
        std::cout << "🎯 Driver activo y escuchando inputs..." << std::endl;
        std::cout << "🎵 Presiona Ctrl+C para salir" << std::endl;
        std::cout << "" << std::endl;
        
        // Bucle principal
        while (true) {
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }
        
    } catch (const std::exception& e) {
        std::cout << "❌ Error: " << e.what() << std::endl;
        if (driver) {
            delete driver;
        }
        return 1;
    }
    
    return 0;
} 