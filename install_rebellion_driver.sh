#!/bin/bash

echo "🎹 ========================================="
echo "🎹 Instalación Rebellion Maschine Driver"
echo "🎹 Basado en el proyecto Rebellion"
echo "🎹 ========================================="
echo

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Este driver solo funciona en macOS"
    exit 1
fi

# Check if Xcode command line tools are installed
if ! command -v clang++ &> /dev/null; then
    echo "❌ Xcode Command Line Tools no encontrados"
    echo "💡 Instala con: xcode-select --install"
    exit 1
fi

echo "✅ Xcode Command Line Tools encontrados"

# Compile the driver
echo "🔨 Compilando driver..."
make -f Makefile.rebellion clean
make -f Makefile.rebellion

if [ $? -ne 0 ]; then
    echo "❌ Error compilando el driver"
    exit 1
fi

echo "✅ Driver compilado correctamente"

# Install the driver
echo "📦 Instalando driver..."
sudo cp rebellion-maschine-driver /usr/local/bin/
sudo chmod +x /usr/local/bin/rebellion-maschine-driver

if [ $? -eq 0 ]; then
    echo "✅ Driver instalado en /usr/local/bin/"
else
    echo "❌ Error instalando el driver"
    exit 1
fi

# Create symlink for easy access
if [ ! -L "/usr/local/bin/maschine-rebellion" ]; then
    sudo ln -sf /usr/local/bin/rebellion-maschine-driver /usr/local/bin/maschine-rebellion
    echo "✅ Symlink creado: maschine-rebellion"
fi

echo
echo "🎯 Instalación completada!"
echo
echo "📋 Uso:"
echo "  maschine-rebellion                    # Ejecutar driver"
echo "  ./test_rebellion_leds.sh             # Test de LEDs"
echo
echo "💡 Comandos disponibles en el driver:"
echo "  test     - Patrón de prueba"
echo "  rainbow  - Patrón arcoíris"
echo "  allon    - Encender todos los pads"
echo "  alloff   - Apagar todos los pads"
echo "  quit     - Salir"
echo
echo "🚀 ¡Tu Maschine Mikro ahora debería funcionar con LEDs!" 