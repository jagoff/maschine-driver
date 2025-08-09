#!/bin/bash

# Instalación Completa del Maschine Driver
# Incluye driver + servicio del sistema

echo "🎹 ========================================="
echo "🎹 INSTALACIÓN COMPLETA - MASCHINE DRIVER"
echo "🎹 ========================================="

# Verificar que estamos en el directorio correcto
if [ ! -f "MaschineMikroDriver_User.cpp" ]; then
    echo "❌ Error: No se encontraron archivos del driver"
    echo "Asegúrate de estar en el directorio del proyecto"
    exit 1
fi

# Verificar permisos de administrador
if [ "$EUID" -ne 0 ]; then
    echo "🔐 Necesario ejecutar como administrador para instalación completa"
    echo "💡 Ejecutando con sudo..."
    sudo "$0" "$@"
    exit $?
fi

# Paso 1: Compilar el driver
echo ""
echo "🔧 Paso 1: Compilando el driver..."
if [ ! -f "./maschine_driver_final" ]; then
    g++ -std=c++11 -framework CoreMIDI -framework CoreFoundation -framework IOKit -o maschine_driver_final MaschineMikroDriver_User.cpp maschine_native_driver.cpp
    
    if [ $? -ne 0 ]; then
        echo "❌ Error de compilación"
        exit 1
    fi
fi
echo "✅ Driver compilado correctamente"

# Paso 2: Instalar el driver
echo ""
echo "📁 Paso 2: Instalando el driver..."
INSTALL_DIR="/usr/local/bin"
cp ./maschine_driver_final "$INSTALL_DIR/maschine_driver"
chmod +x "$INSTALL_DIR/maschine_driver"

if [ $? -eq 0 ]; then
    echo "✅ Driver instalado en: $INSTALL_DIR/maschine_driver"
else
    echo "❌ Error instalando driver"
    exit 1
fi

# Paso 3: Instalar como servicio del sistema
echo ""
echo "🔧 Paso 3: Instalando como servicio del sistema..."

# Crear directorio de logs
mkdir -p /var/log

# Copiar archivo de servicio
SERVICE_PATH="/Library/LaunchDaemons/com.maschine.driver.plist"
cp maschine_driver_service.plist "$SERVICE_PATH"

# Establecer permisos correctos
chown root:wheel "$SERVICE_PATH"
chmod 644 "$SERVICE_PATH"

if [ $? -eq 0 ]; then
    echo "✅ Servicio instalado en: $SERVICE_PATH"
else
    echo "❌ Error instalando servicio"
    exit 1
fi

# Paso 4: Instalar script de control
echo ""
echo "🎛️ Paso 4: Instalando script de control..."
chmod +x maschine_driver_control.sh
cp maschine_driver_control.sh "$INSTALL_DIR/maschine_control"
chmod +x "$INSTALL_DIR/maschine_control"

if [ $? -eq 0 ]; then
    echo "✅ Script de control instalado en: $INSTALL_DIR/maschine_control"
else
    echo "❌ Error instalando script de control"
    exit 1
fi

# Paso 5: Verificar instalación
echo ""
echo "🔍 Paso 5: Verificando instalación..."

# Verificar driver
if [ -f "$INSTALL_DIR/maschine_driver" ]; then
    echo "✅ Driver verificado"
else
    echo "❌ Driver no encontrado"
    exit 1
fi

# Verificar servicio
if [ -f "$SERVICE_PATH" ]; then
    echo "✅ Servicio verificado"
else
    echo "❌ Servicio no encontrado"
    exit 1
fi

# Verificar script de control
if [ -f "$INSTALL_DIR/maschine_control" ]; then
    echo "✅ Script de control verificado"
else
    echo "❌ Script de control no encontrado"
    exit 1
fi

# Paso 6: Test de conexión
echo ""
echo "🧪 Paso 6: Probando conexión..."
"$INSTALL_DIR/maschine_driver" --test-connection

if [ $? -eq 0 ]; then
    echo "✅ Conexión exitosa"
else
    echo "⚠️  Problemas de conexión (puede ser normal si no hay dispositivo conectado)"
fi

# Paso 7: Mostrar información final
echo ""
echo "🎉 ========================================="
echo "🎉 INSTALACIÓN COMPLETA EXITOSA"
echo "🎉 ========================================="
echo ""
echo "✅ Driver instalado en: $INSTALL_DIR/maschine_driver"
echo "✅ Servicio instalado en: $SERVICE_PATH"
echo "✅ Script de control instalado en: $INSTALL_DIR/maschine_control"
echo ""
echo "🎛️ COMANDOS DISPONIBLES:"
echo "  maschine_driver --help              # Ayuda del driver"
echo "  maschine_control help               # Ayuda del control"
echo "  maschine_control install            # Instalar servicio"
echo "  maschine_control load               # Cargar servicio"
echo "  maschine_control unload             # Descargar servicio"
echo "  maschine_control start              # Iniciar manualmente"
echo "  maschine_control stop               # Detener manualmente"
echo "  maschine_control status             # Ver estado"
echo "  maschine_control logs               # Ver logs"
echo "  maschine_control debug              # Modo debug"
echo "  maschine_control test               # Probar conexión"
echo ""
echo "🚀 PRÓXIMOS PASOS:"
echo "  1. maschine_control load            # Cargar como servicio"
echo "  2. maschine_control status          # Verificar estado"
echo "  3. maschine_control logs            # Monitorear logs"
echo ""
echo "🎹 El driver está listo para usar!" 