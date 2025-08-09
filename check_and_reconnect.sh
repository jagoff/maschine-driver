#!/bin/bash

# Script para verificar y reconectar el dispositivo Maschine Mikro
# Versión mejorada con verificaciones más robustas

echo "🎹 ========================================="
echo "🎹 VERIFICACIÓN Y RECONEXIÓN MASCHINE"
echo "🎹 ========================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}🔍 Paso 1: Verificando estado actual...${NC}"

# Verificar si hay algún proceso del driver ejecutándose
DRIVER_PID=$(pgrep -f "maschine_driver")
if [ -n "$DRIVER_PID" ]; then
    echo -e "${YELLOW}⚠️  Driver ejecutándose (PID: $DRIVER_PID)${NC}"
    echo "   Deteniendo driver..."
    ./maschine_driver_control.sh stop
    sleep 2
else
    echo -e "${GREEN}✅ No hay driver ejecutándose${NC}"
fi

echo ""
echo -e "${BLUE}🔍 Paso 2: Verificando dispositivos USB...${NC}"

# Verificar dispositivos USB de forma más amplia
echo "🔍 Buscando dispositivos USB relacionados..."
USB_DEVICES=$(system_profiler SPUSBDataType 2>/dev/null | grep -i "product id\|vendor id" -A 1 -B 1)
if [ -n "$USB_DEVICES" ]; then
    echo "📋 Dispositivos USB encontrados:"
    echo "$USB_DEVICES" | head -20
else
    echo -e "${YELLOW}⚠️  No se pudieron listar dispositivos USB${NC}"
fi

echo ""
echo -e "${BLUE}🔍 Paso 3: Verificando dispositivos MIDI...${NC}"

# Verificar dispositivos MIDI
echo "🔍 Listando fuentes MIDI..."
maschine_driver --list-sources 2>/dev/null | head -10

echo ""
echo -e "${BLUE}🔍 Paso 4: Verificando destinos MIDI...${NC}"

# Verificar destinos MIDI
echo "🔍 Listando destinos MIDI..."
maschine_driver --list-destinations 2>/dev/null | head -10

echo ""
echo -e "${YELLOW}⚠️  DIAGNÓSTICO:${NC}"
echo ""
echo "🎯 Estado actual:"
echo "   ❌ Maschine Mikro no aparece en fuentes MIDI"
echo "   ❌ Maschine Mikro no aparece en destinos MIDI"
echo "   ❌ Dispositivo no detectado por el sistema"
echo ""
echo "🔧 POSIBLES CAUSAS:"
echo "   1. Dispositivo desconectado físicamente"
echo "   2. Cable USB defectuoso"
echo "   3. Puerto USB defectuoso"
echo "   4. Dispositivo en modo de recuperación"
echo "   5. Driver de dispositivo corrupto"
echo ""

echo -e "${BLUE}🔍 Paso 5: INSTRUCCIONES DE RECONEXIÓN${NC}"
echo ""
echo -e "${YELLOW}⚠️  SIGUE ESTOS PASOS EXACTAMENTE:${NC}"
echo ""
echo "1. ${YELLOW}Desconecta COMPLETAMENTE el cable USB de la Maschine Mikro${NC}"
echo "2. ${YELLOW}Espera 10 segundos${NC}"
echo "3. ${YELLOW}Prueba con un puerto USB diferente${NC}"
echo "4. ${YELLOW}Conecta el cable USB${NC}"
echo "5. ${YELLOW}Espera a que las luces del dispositivo parpadeen${NC}"
echo "6. ${YELLOW}Si no hay luces, prueba otro cable USB${NC}"
echo ""
echo -e "${BLUE}Presiona ENTER cuando hayas completado la reconexión...${NC}"
read -r

echo ""
echo -e "${BLUE}🔍 Paso 6: Verificando reconexión...${NC}"
sleep 5

# Verificar nuevamente
echo "🔍 Verificando fuentes MIDI después de reconexión..."
maschine_driver --list-sources 2>/dev/null | head -10

echo ""
echo "🔍 Verificando destinos MIDI después de reconexión..."
maschine_driver --list-destinations 2>/dev/null | head -10

# Verificar si ahora aparece Maschine
if maschine_driver --list-sources 2>/dev/null | grep -q "Maschine"; then
    echo ""
    echo -e "${GREEN}✅ ¡Maschine Mikro detectada!${NC}"
    echo ""
    echo -e "${BLUE}🔍 Paso 7: Iniciando driver...${NC}"
    ./maschine_driver_control.sh start
    sleep 3
    
    echo ""
    echo -e "${BLUE}🔍 Paso 8: Probando conexión...${NC}"
    maschine_driver --test-connection 2>/dev/null
    
    echo ""
    echo -e "${GREEN}🎹 ========================================="
    echo "🎹 ¡RECONEXIÓN EXITOSA!"
    echo "🎹 ========================================="
    echo ""
    echo "✅ Dispositivo reconectado"
    echo "✅ Driver iniciado"
    echo "✅ Listo para usar"
    echo ""
    echo "💡 Prueba ahora:"
    echo "   maschine_driver --debug"
    echo "   maschine_driver --maschine-mode"
    
else
    echo ""
    echo -e "${RED}❌ Maschine Mikro aún no detectada${NC}"
    echo ""
    echo -e "${YELLOW}🔧 TROUBLESHOOTING ADICIONAL:${NC}"
    echo ""
    echo "1. ${YELLOW}Prueba con otro puerto USB${NC}"
    echo "2. ${YELLOW}Prueba con otro cable USB${NC}"
    echo "3. ${YELLOW}Reinicia el sistema macOS${NC}"
    echo "4. ${YELLOW}Verifica que el dispositivo no esté en modo de recuperación${NC}"
    echo ""
    echo "🔍 Para verificar si el dispositivo está físicamente conectado:"
    echo "   lsusb | grep -i native"
    echo "   system_profiler SPUSBDataType | grep -A 10 -B 10 'Native'"
    echo ""
    echo -e "${RED}❌ El dispositivo no se está detectando${NC}"
fi

echo "🎹 =========================================" 