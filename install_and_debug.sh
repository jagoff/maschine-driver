#!/bin/bash

echo "🎹 ========================================="
echo "🎹 INSTALACIÓN Y DEBUG - MASCHINE DRIVER"
echo "🎹 ========================================="

# Verificar que el driver existe
if [ ! -f "./maschine_driver_final" ]; then
    echo "❌ Error: Driver no encontrado. Compilando..."
    g++ -std=c++11 -framework CoreMIDI -framework CoreFoundation -framework IOKit -o maschine_driver_final MaschineMikroDriver_User.cpp maschine_native_driver.cpp
    if [ $? -ne 0 ]; then
        echo "❌ Error de compilación"
        exit 1
    fi
fi

echo "✅ Driver compilado correctamente"

# Crear directorio de instalación
INSTALL_DIR="/usr/local/bin"
echo "📁 Instalando en: $INSTALL_DIR"

# Verificar permisos de administrador
if [ "$EUID" -ne 0 ]; then
    echo "🔐 Necesario ejecutar como administrador para instalar en $INSTALL_DIR"
    echo "💡 Ejecutando con sudo..."
    sudo cp ./maschine_driver_final "$INSTALL_DIR/maschine_driver"
    sudo chmod +x "$INSTALL_DIR/maschine_driver"
else
    cp ./maschine_driver_final "$INSTALL_DIR/maschine_driver"
    chmod +x "$INSTALL_DIR/maschine_driver"
fi

if [ $? -eq 0 ]; then
    echo "✅ Driver instalado en: $INSTALL_DIR/maschine_driver"
else
    echo "❌ Error instalando driver"
    exit 1
fi

# Verificar dispositivos MIDI disponibles
echo ""
echo "🔍 ========================================="
echo "🔍 VERIFICACIÓN DE DISPOSITIVOS MIDI"
echo "🔍 ========================================="

echo "📡 Dispositivos MIDI disponibles:"
system_profiler SPUSBDataType | grep -A 5 -B 5 -i "maschine\|native instruments" || echo "   No se encontraron dispositivos Maschine en USB"

echo ""
echo "🎵 Fuentes MIDI:"
maschine_driver --list-sources 2>/dev/null || echo "   No se pueden listar fuentes MIDI"

echo ""
echo "🎵 Destinos MIDI:"
maschine_driver --list-destinations 2>/dev/null || echo "   No se pueden listar destinos MIDI"

# Test de conexión
echo ""
echo "🎹 ========================================="
echo "🎹 TEST DE CONEXIÓN Y DEBUG"
echo "🎹 ========================================="

echo "🎯 Iniciando driver en modo debug..."
echo "💡 Presiona Ctrl+C para detener el debug"
echo ""

# Ejecutar driver en modo debug
maschine_driver --debug

echo ""
echo "🎹 ========================================="
echo "🎹 INSTALACIÓN COMPLETADA"
echo "🎹 ========================================="
echo "✅ Driver instalado en: $INSTALL_DIR/maschine_driver"
echo "✅ Para usar: maschine_driver"
echo "✅ Para debug: maschine_driver --debug"
echo "✅ Para ayuda: maschine_driver --help"
echo ""
echo "🎯 El driver está listo para usar en modo Maschine nativo!" 