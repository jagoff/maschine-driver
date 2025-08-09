#!/bin/bash

# Script final para verificar el estado físico del dispositivo y reiniciar completamente el sistema MIDI

echo "🎹 ========================================="
echo "🎹 VERIFICACIÓN FINAL MASCHINE MIKRO"
echo "🎹 ========================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}🔍 Paso 1: Verificación física del dispositivo...${NC}"

echo "🎯 VERIFICACIÓN FÍSICA:"
echo ""
echo "1. ${YELLOW}¿El dispositivo está encendido?${NC}"
echo "   - Debería tener luces encendidas"
echo "   - El display debería mostrar algo"
echo ""
echo "2. ${YELLOW}¿Qué muestra el display?${NC}"
echo "   - 'Maschine Mikro start maschine or press shift+f1 for midi mode'"
echo "   - O algo diferente?"
echo ""
echo "3. ${YELLOW}¿Las luces están encendidas?${NC}"
echo "   - Debería haber luces en los pads"
echo "   - Debería haber luces en los botones"
echo ""
echo -e "${BLUE}Presiona ENTER cuando hayas verificado el estado físico...${NC}"
read -r

echo ""
echo -e "${BLUE}🔍 Paso 2: Deteniendo completamente el sistema MIDI...${NC}"

# Detener driver
./maschine_driver_control.sh stop
sleep 2

# Matar todos los procesos relacionados
pkill -f "maschine_driver" 2>/dev/null
pkill -f "MIDIServer" 2>/dev/null
sleep 2

echo ""
echo -e "${BLUE}🔍 Paso 3: Reiniciando servicios de audio y MIDI...${NC}"

# Reiniciar Core Audio
echo "🔄 Reiniciando Core Audio..."
sudo launchctl unload /System/Library/LaunchDaemons/com.apple.audio.coreaudiod.plist 2>/dev/null
sleep 3
sudo launchctl load /System/Library/LaunchDaemons/com.apple.audio.coreaudiod.plist 2>/dev/null
sleep 5

echo ""
echo -e "${BLUE}🔍 Paso 4: Verificando dispositivos USB...${NC}"

# Verificar dispositivos USB
echo "🔍 Verificando dispositivos USB..."
if system_profiler SPUSBDataType 2>/dev/null | grep -i "native\|maschine" > /dev/null; then
    echo -e "${GREEN}✅ Dispositivo Native Instruments detectado en USB${NC}"
    system_profiler SPUSBDataType 2>/dev/null | grep -i "native\|maschine" -A 3 -B 3
else
    echo -e "${RED}❌ Dispositivo Native Instruments NO detectado en USB${NC}"
    echo "   Esto indica un problema de conexión física"
fi

echo ""
echo -e "${BLUE}🔍 Paso 5: Verificando dispositivos MIDI del sistema...${NC}"

# Verificar dispositivos MIDI del sistema
echo "🔍 Verificando dispositivos MIDI del sistema..."
MIDI_DEVICES=$(system_profiler SPAudioDataType 2>/dev/null | grep -i "midi\|maschine\|native" -A 2 -B 2)
if [ -n "$MIDI_DEVICES" ]; then
    echo "📋 Dispositivos MIDI encontrados:"
    echo "$MIDI_DEVICES"
else
    echo -e "${YELLOW}⚠️  No se encontraron dispositivos MIDI específicos${NC}"
fi

echo ""
echo -e "${YELLOW}⚠️  INSTRUCCIONES IMPORTANTES:${NC}"
echo ""
echo "El dispositivo está conectado físicamente pero no se registra en MIDI."
echo "Esto puede ser porque:"
echo "1. Está en modo MIDI en lugar de modo Maschine"
echo "2. Necesita un reinicio completo del dispositivo"
echo "3. El sistema MIDI necesita más tiempo para detectarlo"
echo ""
echo -e "${YELLOW}⚠️  SIGUE ESTOS PASOS:${NC}"
echo ""
echo "1. ${YELLOW}Presiona SHIFT + F1 en el dispositivo físico${NC}"
echo "2. ${YELLOW}Espera a que el display cambie${NC}"
echo "3. ${YELLOW}Presiona SHIFT + F1 nuevamente para volver a modo Maschine${NC}"
echo "4. ${YELLOW}O simplemente presiona cualquier pad para activar${NC}"
echo "5. ${YELLOW}Espera 10 segundos después de hacer esto${NC}"
echo ""
echo -e "${BLUE}Presiona ENTER cuando hayas completado estos pasos...${NC}"
read -r

echo ""
echo -e "${BLUE}🔍 Paso 6: Iniciando driver después del reinicio...${NC}"

# Iniciar driver
./maschine_driver_control.sh start
sleep 5

echo ""
echo -e "${BLUE}🔍 Paso 7: Verificando detección después del reinicio...${NC}"

# Verificar fuentes MIDI
echo "🔍 Verificando fuentes MIDI después del reinicio:"
maschine_driver --list-sources 2>/dev/null

echo ""
echo "🔍 Verificando destinos MIDI después del reinicio:"
maschine_driver --list-destinations 2>/dev/null

echo ""
echo -e "${BLUE}🔍 Paso 8: Probando conexión completa...${NC}"

# Probar conexión
maschine_driver --test-connection 2>/dev/null

echo ""
echo -e "${BLUE}🔍 Paso 9: Iniciando modo debug para verificación final...${NC}"

echo "🎯 Iniciando modo debug (presiona Ctrl+C para salir)..."
echo "💡 Si ves 'Maschine Mikro Input' en las fuentes, ¡está funcionando!"
echo "💡 Si ves 'modo simulación', el dispositivo aún no se detecta"
echo ""

# Iniciar modo debug
maschine_driver --debug

echo ""
echo -e "${BLUE}🎹 ========================================="
echo "🎹 VERIFICACIÓN FINAL COMPLETADA"
echo "🎹 ========================================="

echo "🎯 RESULTADO FINAL:"
if maschine_driver --list-sources 2>/dev/null | grep -q "Maschine Mikro Input"; then
    echo -e "${GREEN}✅ ¡Maschine Mikro Input detectada!${NC}"
    echo -e "${GREEN}✅ El dispositivo está completamente funcional${NC}"
    echo ""
    echo "💡 El dispositivo está listo para usar:"
    echo "   maschine_driver --maschine-mode"
    echo "   maschine_driver --debug"
else
    echo -e "${YELLOW}⚠️  Maschine Mikro Input aún no detectada${NC}"
    echo -e "${YELLOW}⚠️  El dispositivo puede requerir software oficial${NC}"
    echo ""
    echo "🔧 Posibles soluciones:"
    echo "   1. Reinicia el sistema macOS completamente"
    echo "   2. Prueba con otro puerto USB"
    echo "   3. Prueba con otro cable USB"
    echo "   4. Instala el software oficial de Native Instruments"
    echo ""
    echo "💡 El driver está funcionando en modo simulación"
    echo "   Los pads funcionarán pero no serán inputs físicos reales"
fi

echo "🎹 =========================================" 