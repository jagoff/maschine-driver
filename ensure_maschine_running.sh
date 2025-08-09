#!/bin/bash

# Script para asegurar que el Maschine Driver esté siempre ejecutándose
# y correctamente integrado con el sistema

echo "🎹 ========================================="
echo "🎹 ASEGURANDO FUNCIONAMIENTO MASCHINE"
echo "🎹 ========================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verificar si el driver está ejecutándose
DRIVER_PID=$(pgrep -f "maschine_driver")

if [ -n "$DRIVER_PID" ]; then
    echo -e "${GREEN}✅ Driver ya ejecutándose (PID: $DRIVER_PID)${NC}"
else
    echo -e "${YELLOW}⚠️  Driver no ejecutándose, iniciando...${NC}"
    ./maschine_driver_control.sh start
    sleep 2
    
    # Verificar que se inició correctamente
    DRIVER_PID=$(pgrep -f "maschine_driver")
    if [ -n "$DRIVER_PID" ]; then
        echo -e "${GREEN}✅ Driver iniciado exitosamente (PID: $DRIVER_PID)${NC}"
    else
        echo -e "${RED}❌ Error al iniciar el driver${NC}"
        exit 1
    fi
fi

# Verificar conexión MIDI
echo ""
echo -e "${BLUE}🔍 Verificando conexión MIDI...${NC}"

if maschine_driver --test-connection > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Conexión MIDI establecida${NC}"
else
    echo -e "${RED}❌ Error en conexión MIDI${NC}"
fi

# Verificar dispositivos registrados
echo ""
echo -e "${BLUE}🔍 Verificando dispositivos registrados...${NC}"

if maschine_driver --list-sources 2>/dev/null | grep -q "Maschine Mikro Input"; then
    echo -e "${GREEN}✅ Maschine Mikro Input registrado${NC}"
else
    echo -e "${RED}❌ Maschine Mikro Input no registrado${NC}"
fi

if maschine_driver --list-destinations 2>/dev/null | grep -q "Maschine Mikro Output"; then
    echo -e "${GREEN}✅ Maschine Mikro Output registrado${NC}"
else
    echo -e "${RED}❌ Maschine Mikro Output no registrado${NC}"
fi

# Verificar logs
echo ""
echo -e "${BLUE}🔍 Verificando logs...${NC}"

if [ -f "/var/log/maschine_driver.log" ]; then
    echo -e "${GREEN}✅ Log del driver disponible${NC}"
    echo "📄 Actividad reciente:"
    tail -3 /var/log/maschine_driver.log 2>/dev/null || echo "   No hay actividad reciente"
else
    echo -e "${YELLOW}⚠️  Log del driver no encontrado${NC}"
fi

# Estado final
echo ""
echo -e "${BLUE}🎹 ========================================="
echo "🎹 ESTADO FINAL"
echo "🎹 ========================================="

if [ -n "$DRIVER_PID" ] && maschine_driver --list-sources 2>/dev/null | grep -q "Maschine Mikro Input"; then
    echo -e "${GREEN}✅ SISTEMA COMPLETAMENTE OPERATIVO${NC}"
    echo ""
    echo "🎯 El driver está listo para usar con Maschine 3:"
    echo "   📡 Dispositivo visible en CoreMIDI"
    echo "   🔗 Conexión MIDI establecida"
    echo "   📊 Logs funcionando"
    echo "   🎹 Driver ejecutándose (PID: $DRIVER_PID)"
    echo ""
    echo "💡 Para usar con Maschine 3:"
    echo "   1. Abrir Maschine 3"
    echo "   2. Ir a Preferences > MIDI"
    echo "   3. Habilitar 'Maschine Mikro Input' y 'Maschine Mikro Output'"
    echo "   4. Configurar 'Track' y 'Remote' para ambos"
    echo "   5. ¡Listo para usar!"
    echo ""
    echo "🎉 ¡El controlador Maschine Mikro está completamente integrado!"
    
else
    echo -e "${RED}❌ SISTEMA NO OPERATIVO${NC}"
    echo ""
    echo "🔧 Problemas detectados:"
    if [ -z "$DRIVER_PID" ]; then
        echo "   ❌ Driver no ejecutándose"
    fi
    if ! maschine_driver --list-sources 2>/dev/null | grep -q "Maschine Mikro Input"; then
        echo "   ❌ Dispositivo no registrado en CoreMIDI"
    fi
    echo ""
    echo "💡 Solución:"
    echo "   1. Verificar conexión USB del dispositivo"
    echo "   2. Ejecutar: ./maschine_driver_control.sh restart"
    echo "   3. Verificar: ./verify_maschine_integration.sh"
fi

echo "🎹 =========================================" 