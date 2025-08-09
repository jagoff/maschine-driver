#!/bin/bash

# 🎹 VERIFICACIÓN FINAL - MASCHINE MIKRO DRIVER
# Script para verificar que todo el sistema está funcionando correctamente

echo "🎹 ========================================="
echo "🎹 VERIFICACIÓN FINAL MASCHINE MIKRO DRIVER"
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

echo -e "${BLUE}🔍 Verificando componentes del sistema...${NC}"
echo ""

# 1. Verificar que el driver está instalado
echo -e "${YELLOW}1. Verificando driver instalado...${NC}"
if command -v maschine_driver &> /dev/null; then
    show_status 0 "Driver maschine_driver encontrado en PATH"
else
    show_status 1 "Driver maschine_driver NO encontrado"
fi

# 2. Verificar archivo del driver
echo -e "${YELLOW}2. Verificando archivo del driver...${NC}"
if [ -f "/usr/local/bin/maschine_driver" ]; then
    show_status 0 "Archivo del driver existe en /usr/local/bin/"
else
    show_status 1 "Archivo del driver NO existe"
fi

# 3. Verificar scripts de activación
echo -e "${YELLOW}3. Verificando scripts de activación...${NC}"
scripts=("maschine_final_solution.sh" "test_activate_inputs" "maschine_ultimate_activation.sh")
for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        show_status 0 "Script $script encontrado"
    else
        show_status 1 "Script $script NO encontrado"
    fi
done

# 4. Verificar dispositivos MIDI
echo -e "${YELLOW}4. Verificando dispositivos MIDI...${NC}"
if command -v maschine_driver &> /dev/null; then
    # Ejecutar test de conexión
    if maschine_driver --test-connection &> /dev/null; then
        show_status 0 "Dispositivos MIDI detectados y funcionando"
    else
        show_status 1 "Problema con dispositivos MIDI"
    fi
else
    show_status 1 "No se puede verificar MIDI - driver no disponible"
fi

# 5. Verificar archivos de testing
echo -e "${YELLOW}5. Verificando archivos de testing...${NC}"
test_files=("test_maschine_debug" "list_midi_devices" "debug_midi_devices")
for test_file in "${test_files[@]}"; do
    if [ -f "$test_file" ]; then
        show_status 0 "Archivo de test $test_file encontrado"
    else
        show_status 1 "Archivo de test $test_file NO encontrado"
    fi
done

# 6. Verificar archivos fuente
echo -e "${YELLOW}6. Verificando archivos fuente...${NC}"
source_files=("MaschineMikroDriver_User.cpp" "MaschineMikroDriver_User.h" "maschine_native_driver.cpp")
for source_file in "${source_files[@]}"; do
    if [ -f "$source_file" ]; then
        show_status 0 "Archivo fuente $source_file encontrado"
    else
        show_status 1 "Archivo fuente $source_file NO encontrado"
    fi
done

echo ""
echo -e "${BLUE}🎯 RESUMEN DE VERIFICACIÓN${NC}"
echo "========================================"

# Contar éxitos y fallos
success_count=0
total_count=0

# Verificar driver
if command -v maschine_driver &> /dev/null; then
    ((success_count++))
fi
((total_count++))

# Verificar archivo driver
if [ -f "/usr/local/bin/maschine_driver" ]; then
    ((success_count++))
fi
((total_count++))

# Verificar scripts
for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        ((success_count++))
    fi
    ((total_count++))
done

# Verificar MIDI
if command -v maschine_driver &> /dev/null && maschine_driver --test-connection &> /dev/null; then
    ((success_count++))
fi
((total_count++))

# Verificar archivos de test
for test_file in "${test_files[@]}"; do
    if [ -f "$test_file" ]; then
        ((success_count++))
    fi
    ((total_count++))
done

# Verificar archivos fuente
for source_file in "${source_files[@]}"; do
    if [ -f "$source_file" ]; then
        ((success_count++))
    fi
    ((total_count++))
done

# Mostrar resultado final
echo ""
if [ $success_count -eq $total_count ]; then
    echo -e "${GREEN}🎉 ¡VERIFICACIÓN COMPLETA EXITOSA!${NC}"
    echo -e "${GREEN}✅ Todos los componentes están funcionando correctamente${NC}"
    echo ""
    echo -e "${BLUE}🚀 El sistema está listo para uso:${NC}"
    echo "   • Ejecuta: ./maschine_final_solution.sh"
    echo "   • O usa: ./test_activate_inputs"
    echo "   • Driver: maschine_driver --help"
else
    echo -e "${RED}⚠️  VERIFICACIÓN INCOMPLETA${NC}"
    echo -e "${RED}❌ $success_count de $total_count componentes funcionando${NC}"
    echo ""
    echo -e "${YELLOW}🔧 Componentes faltantes detectados${NC}"
    echo "   • Revisa los errores arriba"
    echo "   • Ejecuta: ./maschine_complete_install.sh"
fi

echo ""
echo -e "${BLUE}📊 Estadísticas:${NC}"
echo "   • Componentes verificados: $total_count"
echo "   • Componentes funcionando: $success_count"
echo "   • Porcentaje de éxito: $((success_count * 100 / total_count))%"

echo ""
echo "🎹 ========================================="
echo "🎹 VERIFICACIÓN FINALIZADA"
echo "🎹 =========================================" 