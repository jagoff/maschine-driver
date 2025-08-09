#!/bin/bash

# Script para verificar integración del Maschine Driver con el sistema
# y visibilidad en Maschine 3 de Native Instruments

echo "🎹 ========================================="
echo "🎹 VERIFICACIÓN DE INTEGRACIÓN MASCHINE"
echo "🎹 ========================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}🔍 Paso 1: Verificando estado del driver...${NC}"
./maschine_driver_control.sh status

echo ""
echo -e "${BLUE}🔍 Paso 2: Verificando dispositivos MIDI del sistema...${NC}"

# Verificar MIDIServer
if pgrep -f "MIDIServer" > /dev/null; then
    echo -e "${GREEN}✅ MIDIServer ejecutándose${NC}"
else
    echo -e "${RED}❌ MIDIServer no ejecutándose${NC}"
fi

# Verificar Audio MIDI Setup
if pgrep -f "Audio MIDI Setup" > /dev/null; then
    echo -e "${GREEN}✅ Audio MIDI Setup ejecutándose${NC}"
else
    echo -e "${YELLOW}⚠️  Audio MIDI Setup no ejecutándose${NC}"
fi

echo ""
echo -e "${BLUE}🔍 Paso 3: Verificando dispositivos MIDI disponibles...${NC}"

# Listar fuentes MIDI
echo "📡 Fuentes MIDI:"
maschine_driver --list-sources 2>/dev/null | grep -E "(Maschine|Bus|Axe-Fx)" || echo "   No se pueden listar fuentes"

# Listar destinos MIDI
echo ""
echo "📡 Destinos MIDI:"
maschine_driver --list-destinations 2>/dev/null | grep -E "(Maschine|Bus|Axe-Fx)" || echo "   No se pueden listar destinos"

echo ""
echo -e "${BLUE}🔍 Paso 4: Verificando conexión con Maschine Mikro...${NC}"

# Probar conexión
if maschine_driver --test-connection > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Conexión con Maschine Mikro exitosa${NC}"
else
    echo -e "${RED}❌ Error en conexión con Maschine Mikro${NC}"
fi

echo ""
echo -e "${BLUE}🔍 Paso 5: Verificando logs del driver...${NC}"

# Verificar logs
if [ -f "/var/log/maschine_driver.log" ]; then
    echo -e "${GREEN}✅ Log del driver disponible${NC}"
    echo "📄 Últimas líneas del log:"
    tail -5 /var/log/maschine_driver.log 2>/dev/null || echo "   No se puede leer el log"
else
    echo -e "${YELLOW}⚠️  Log del driver no encontrado${NC}"
fi

echo ""
echo -e "${BLUE}🔍 Paso 6: Verificando integración con sistema MIDI...${NC}"

# Verificar si el driver está registrado en CoreMIDI
if maschine_driver --list-sources 2>/dev/null | grep -q "Maschine Mikro Input"; then
    echo -e "${GREEN}✅ Maschine Mikro Input registrado en CoreMIDI${NC}"
else
    echo -e "${RED}❌ Maschine Mikro Input no registrado en CoreMIDI${NC}"
fi

if maschine_driver --list-destinations 2>/dev/null | grep -q "Maschine Mikro Output"; then
    echo -e "${GREEN}✅ Maschine Mikro Output registrado en CoreMIDI${NC}"
else
    echo -e "${RED}❌ Maschine Mikro Output no registrado en CoreMIDI${NC}"
fi

echo ""
echo -e "${BLUE}🔍 Paso 7: Verificando compatibilidad con Maschine 3...${NC}"

echo "📋 Para que Maschine 3 detecte el dispositivo:"
echo "   1. ✅ Driver debe estar ejecutándose"
echo "   2. ✅ Dispositivo debe estar conectado por USB"
echo "   3. ✅ Dispositivo debe aparecer en Audio MIDI Setup"
echo "   4. ✅ Maschine 3 debe estar configurado para usar MIDI externo"

echo ""
echo -e "${BLUE}🔍 Paso 8: Instrucciones para Maschine 3...${NC}"

echo "🎯 En Maschine 3:"
echo "   1. Ir a Preferences > MIDI"
echo "   2. Buscar 'Maschine Mikro Input' en la lista"
echo "   3. Habilitar 'Track' y 'Remote'"
echo "   4. Buscar 'Maschine Mikro Output' en la lista"
echo "   5. Habilitar 'Track' y 'Remote'"
echo "   6. Reiniciar Maschine 3 si es necesario"

echo ""
echo -e "${BLUE}🔍 Paso 9: Verificando estado final...${NC}"

# Estado final
DRIVER_PID=$(pgrep -f "maschine_driver")
if [ -n "$DRIVER_PID" ]; then
    echo -e "${GREEN}✅ Driver ejecutándose (PID: $DRIVER_PID)${NC}"
else
    echo -e "${RED}❌ Driver no ejecutándose${NC}"
    echo "💡 Ejecuta: ./maschine_driver_control.sh start"
fi

echo ""
echo -e "${BLUE}🎹 ========================================="
echo "🎹 RESUMEN DE INTEGRACIÓN"
echo "🎹 ========================================="

if [ -n "$DRIVER_PID" ] && maschine_driver --list-sources 2>/dev/null | grep -q "Maschine Mikro Input"; then
    echo -e "${GREEN}✅ INTEGRACIÓN EXITOSA${NC}"
    echo "   🎹 Driver funcionando correctamente"
    echo "   📡 Dispositivo visible en CoreMIDI"
    echo "   🎯 Listo para usar con Maschine 3"
    echo ""
    echo "💡 Próximos pasos:"
    echo "   1. Abrir Maschine 3"
    echo "   2. Configurar MIDI en Preferences"
    echo "   3. Habilitar Maschine Mikro Input/Output"
    echo "   4. ¡Disfrutar del controlador!"
    
else
    echo -e "${RED}❌ INTEGRACIÓN INCOMPLETA${NC}"
    echo "   🔧 Revisar estado del driver"
    echo "   📡 Verificar conexión MIDI"
    echo "   🎯 Configurar Maschine 3 manualmente"
    echo ""
    echo "💡 Solución:"
    echo "   1. ./maschine_driver_control.sh start"
    echo "   2. Verificar conexión USB"
    echo "   3. Configurar MIDI en Maschine 3"
fi

echo "🎹 =========================================" 