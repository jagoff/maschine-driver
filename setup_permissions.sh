#!/bin/bash

# Script de configuración de permisos para Maschine Driver
# Ejecutar con: sudo ./setup_permissions.sh

echo "🔧 Configurando permisos para Maschine Driver..."

# Verificar permisos de administrador
if [ "$EUID" -ne 0 ]; then
    echo "🔐 Necesario ejecutar como administrador"
    echo "💡 Ejecuta con: sudo $0"
    exit 1
fi

# Crear directorio de logs si no existe
echo "📁 Creando directorio de logs..."
mkdir -p /var/log

# Crear archivos de log si no existen
echo "📄 Creando archivos de log..."
touch /var/log/maschine_driver.log
touch /var/log/maschine_driver_error.log

# Establecer permisos correctos
echo "🔐 Estableciendo permisos..."
chmod 666 /var/log/maschine_driver.log
chmod 666 /var/log/maschine_driver_error.log

# Establecer propietario correcto (usuario actual)
CURRENT_USER=$(who am i | awk '{print $1}')
echo "👤 Estableciendo propietario: $CURRENT_USER"
chown $CURRENT_USER:staff /var/log/maschine_driver.log
chown $CURRENT_USER:staff /var/log/maschine_driver_error.log

# Verificar configuración
echo ""
echo "🔍 Verificando configuración..."
ls -la /var/log/maschine_driver*

echo ""
echo "✅ Permisos configurados correctamente"
echo "💡 Ahora puedes usar: ./maschine_driver_control.sh start" 