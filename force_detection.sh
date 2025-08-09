#!/bin/bash

# Script para forzar la detección y activación del dispositivo Maschine Mikro
# El dispositivo está conectado pero no se detecta como fuente MIDI

echo "🎹 ========================================="
echo "🎹 FORZANDO DETECCIÓN MASCHINE MIKRO"
echo "🎹 ========================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}🔍 Paso 1: Deteniendo todos los procesos MIDI...${NC}"

# Detener driver
./maschine_driver_control.sh stop
sleep 2

# Matar cualquier proceso relacionado
pkill -f "maschine_driver" 2>/dev/null
pkill -f "MIDIServer" 2>/dev/null
sleep 2

echo ""
echo -e "${BLUE}🔍 Paso 2: Reiniciando servicios MIDI...${NC}"

# Reiniciar Audio MIDI Setup
echo "🔄 Reiniciando Audio MIDI Setup..."
sudo launchctl unload /System/Library/LaunchDaemons/com.apple.audio.coreaudiod.plist 2>/dev/null
sleep 2
sudo launchctl load /System/Library/LaunchDaemons/com.apple.audio.coreaudiod.plist 2>/dev/null
sleep 3

echo ""
echo -e "${BLUE}🔍 Paso 3: Verificando dispositivos USB...${NC}"

# Verificar si el dispositivo está físicamente conectado
echo "🔍 Verificando conexión USB..."
if system_profiler SPUSBDataType 2>/dev/null | grep -i "native\|maschine" > /dev/null; then
    echo -e "${GREEN}✅ Dispositivo Native Instruments detectado en USB${NC}"
else
    echo -e "${YELLOW}⚠️  Dispositivo no detectado en USB - verificando MIDI...${NC}"
fi

echo ""
echo -e "${BLUE}🔍 Paso 4: Verificando dispositivos MIDI del sistema...${NC}"

# Verificar dispositivos MIDI del sistema
echo "🔍 Listando dispositivos MIDI del sistema..."
system_profiler SPAudioDataType 2>/dev/null | grep -i "midi\|maschine\|native" -A 2 -B 2 || echo "   No se encontraron dispositivos MIDI específicos"

echo ""
echo -e "${YELLOW}⚠️  INSTRUCCIONES IMPORTANTES:${NC}"
echo ""
echo "El dispositivo está conectado pero no se detecta como fuente MIDI."
echo "Esto puede ser porque:"
echo "1. Está en modo MIDI en lugar de modo Maschine"
echo "2. Necesita un reinicio completo"
echo "3. Está en estado de espera"
echo ""
echo -e "${YELLOW}⚠️  SIGUE ESTOS PASOS:${NC}"
echo ""
echo "1. ${YELLOW}Presiona SHIFT + F1 en el dispositivo físico${NC}"
echo "2. ${YELLOW}Espera a que el display cambie${NC}"
echo "3. ${YELLOW}Presiona SHIFT + F1 nuevamente para volver a modo Maschine${NC}"
echo "4. ${YELLOW}O simplemente presiona cualquier pad para activar${NC}"
echo ""
echo -e "${BLUE}Presiona ENTER cuando hayas hecho esto...${NC}"
read -r

echo ""
echo -e "${BLUE}🔍 Paso 5: Iniciando driver con detección forzada...${NC}"

# Iniciar driver
./maschine_driver_control.sh start
sleep 3

echo ""
echo -e "${BLUE}🔍 Paso 6: Verificando detección...${NC}"

# Verificar si ahora se detecta
echo "🔍 Verificando fuentes MIDI..."
maschine_driver --list-sources 2>/dev/null

echo ""
echo "🔍 Verificando destinos MIDI..."
maschine_driver --list-destinations 2>/dev/null

echo ""
echo -e "${BLUE}🔍 Paso 7: Probando conexión completa...${NC}"

# Probar conexión
maschine_driver --test-connection 2>/dev/null

echo ""
echo -e "${BLUE}🔍 Paso 8: Iniciando modo debug para verificar...${NC}"

echo "🎯 Iniciando modo debug (presiona Ctrl+C para salir)..."
echo "💡 Si ves 'Maschine Mikro Input' en las fuentes, ¡está funcionando!"
echo ""

# Iniciar modo debug
maschine_driver --debug

echo ""
echo -e "${BLUE}🎹 ========================================="
echo "🎹 VERIFICACIÓN COMPLETADA"
echo "🎹 ========================================="

echo "🎯 RESULTADO:"
if maschine_driver --list-sources 2>/dev/null | grep -q "Maschine Mikro Input"; then
    echo -e "${GREEN}✅ ¡Maschine Mikro Input detectada!${NC}"
    echo -e "${GREEN}✅ Dispositivo completamente funcional${NC}"
    echo ""
    echo "💡 El dispositivo está listo para usar:"
    echo "   maschine_driver --maschine-mode"
    echo "   maschine_driver --debug"
else
    echo -e "${YELLOW}⚠️  Maschine Mikro Input aún no detectada${NC}"
    echo -e "${YELLOW}⚠️  El dispositivo puede estar en modo MIDI${NC}"
    echo ""
    echo "🔧 Próximos pasos:"
    echo "   1. Presiona SHIFT + F1 en el dispositivo"
    echo "   2. Espera a que el display cambie"
    echo "   3. Presiona SHIFT + F1 nuevamente"
    echo "   4. O reinicia el sistema macOS"
fi

echo "🎹 =========================================" 