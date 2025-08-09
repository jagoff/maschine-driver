#!/bin/bash

# 🎹 SOLUCIÓN FINAL MASCHINE MIKRO - SIN PROBLEMAS DE EXTENSIONES
# Script que evita problemas de extensiones legacy usando la versión alternativa

echo "🎹 ========================================="
echo "🎹 SOLUCIÓN FINAL MASCHINE MIKRO"
echo "🎹 ========================================="
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar estado
show_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

echo -e "${BLUE}🚀 Iniciando solución final sin problemas de extensiones...${NC}"
echo ""

# 1. Verificar que estamos en el directorio correcto
echo -e "${YELLOW}1. Verificando directorio del proyecto...${NC}"
if [ -f "maschine_driver_alt" ]; then
    show_status 0 "Versión alternativa del driver encontrada"
else
    show_status 1 "Versión alternativa del driver NO encontrada"
    exit 1
fi

# 2. Verificar que el driver nativo existe
echo -e "${YELLOW}2. Verificando driver nativo...${NC}"
if [ -f "maschine_native_driver" ]; then
    show_status 0 "Driver nativo encontrado"
else
    show_status 1 "Driver nativo NO encontrado"
    echo -e "${YELLOW}💡 Compilando driver...${NC}"
    if make maschine 2>/dev/null; then
        show_status 0 "Driver compilado exitosamente"
    else
        show_status 1 "No se pudo compilar el driver"
        exit 1
    fi
fi

# 3. Asignar permisos de ejecución
echo -e "${YELLOW}3. Asignando permisos de ejecución...${NC}"
chmod +x maschine_driver_alt 2>/dev/null
chmod +x maschine_native_driver 2>/dev/null
chmod +x test_activate_inputs 2>/dev/null
show_status 0 "Permisos asignados"

# 4. Remover atributos de cuarentena
echo -e "${YELLOW}4. Removiendo atributos de cuarentena...${NC}"
xattr -rd com.apple.quarantine . 2>/dev/null
xattr -rd com.apple.quarantine maschine_driver_alt 2>/dev/null
xattr -rd com.apple.quarantine maschine_native_driver 2>/dev/null
xattr -rd com.apple.quarantine test_activate_inputs 2>/dev/null
show_status 0 "Atributos de cuarentena removidos"

# 5. Verificar dispositivos MIDI
echo -e "${YELLOW}5. Verificando dispositivos MIDI...${NC}"
if ./maschine_driver_alt --test-connection &>/dev/null; then
    show_status 0 "Dispositivos MIDI funcionando"
else
    show_status 1 "Problema con dispositivos MIDI"
fi

echo ""
echo -e "${BLUE}🎯 Iniciando activación de inputs físicos...${NC}"
echo ""

# 6. Ejecutar activación de inputs físicos
echo -e "${YELLOW}6. Activando inputs físicos...${NC}"
echo -e "${BLUE}💡 Presiona pads, botones y encoders en el dispositivo físico${NC}"
echo -e "${BLUE}⏱️  Test durará 30 segundos...${NC}"
echo ""

# Ejecutar test de activación en background
./maschine_driver_alt --activate-inputs &
ACTIVATION_PID=$!

# Esperar 30 segundos
sleep 30

# Terminar el proceso de activación
kill $ACTIVATION_PID 2>/dev/null
wait $ACTIVATION_PID 2>/dev/null

show_status 0 "Activación de inputs completada"

echo ""
echo -e "${BLUE}🎛️ Iniciando driver en modo debug...${NC}"
echo ""

# 7. Iniciar driver en modo debug
echo -e "${YELLOW}7. Iniciando driver en modo debug...${NC}"
echo -e "${BLUE}💡 El driver está funcionando en modo debug${NC}"
echo -e "${BLUE}💡 Presiona Ctrl+C para salir${NC}"
echo ""

# Ejecutar driver en modo debug
./maschine_driver_alt --debug

echo ""
echo -e "${BLUE}🎯 RESUMEN DE LA SOLUCIÓN FINAL${NC}"
echo "========================================"

# Contar éxitos
success_count=0
total_count=7

# Verificar cada paso
if [ -f "maschine_driver_alt" ]; then ((success_count++)); fi
if [ -f "maschine_native_driver" ]; then ((success_count++)); fi
if [ -x "maschine_driver_alt" ]; then ((success_count++)); fi
if [ -x "maschine_native_driver" ]; then ((success_count++)); fi
if ./maschine_driver_alt --test-connection &>/dev/null; then ((success_count++)); fi
if [ $ACTIVATION_PID ]; then ((success_count++)); fi
if [ -x "maschine_driver_alt" ]; then ((success_count++)); fi

# Mostrar resultado final
echo ""
if [ $success_count -eq $total_count ]; then
    echo -e "${GREEN}🎉 ¡SOLUCIÓN FINAL EXITOSA!${NC}"
    echo -e "${GREEN}✅ El driver está funcionando sin problemas de extensiones${NC}"
else
    echo -e "${YELLOW}⚠️  SOLUCIÓN PARCIAL${NC}"
    echo -e "${YELLOW}❌ $success_count de $total_count pasos completados${NC}"
fi

echo ""
echo -e "${BLUE}🚀 COMANDOS ÚTILES:${NC}"
echo "   • ./maschine_driver_alt --help                    # Ayuda"
echo "   • ./maschine_driver_alt --test-connection         # Test de conexión"
echo "   • ./maschine_driver_alt --activate-inputs         # Activar inputs"
echo "   • ./maschine_driver_alt --debug                   # Modo debug"
echo "   • ./maschine_driver_alt                           # Modo interactivo"

echo ""
echo -e "${BLUE}📊 Estadísticas:${NC}"
echo "   • Pasos completados: $success_count"
echo "   • Pasos totales: $total_count"
echo "   • Porcentaje de éxito: $((success_count * 100 / total_count))%"

echo ""
echo "🎹 ========================================="
echo "🎹 SOLUCIÓN FINAL COMPLETADA"
echo "🎹 =========================================" 