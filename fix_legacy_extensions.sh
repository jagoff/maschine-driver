#!/bin/bash

# 🎹 FIX LEGACY EXTENSIONS - MASCHINE MIKRO DRIVER
# Script para resolver problemas de extensiones legacy y permisos

echo "🎹 ========================================="
echo "🎹 FIX LEGACY EXTENSIONS MASCHINE DRIVER"
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

echo -e "${BLUE}🔧 Resolviendo problemas de extensiones legacy...${NC}"
echo ""

# 1. Verificar estado actual de Gatekeeper
echo -e "${YELLOW}1. Verificando estado de Gatekeeper...${NC}"
if sudo spctl --status | grep -q "enabled"; then
    echo -e "${YELLOW}⚠️  Gatekeeper está habilitado${NC}"
    show_status 1 "Gatekeeper activo - puede bloquear extensiones"
else
    show_status 0 "Gatekeeper deshabilitado"
fi

# 2. Remover atributos de cuarentena del driver
echo -e "${YELLOW}2. Removiendo atributos de cuarentena...${NC}"
if sudo xattr -rd com.apple.quarantine /usr/local/bin/maschine_driver 2>/dev/null; then
    show_status 0 "Atributos de cuarentena removidos del driver"
else
    show_status 1 "No se pudieron remover atributos de cuarentena"
fi

# 3. Remover atributos de cuarentena del directorio actual
echo -e "${YELLOW}3. Removiendo atributos de cuarentena del directorio...${NC}"
if sudo xattr -rd com.apple.quarantine . 2>/dev/null; then
    show_status 0 "Atributos de cuarentena removidos del directorio"
else
    show_status 1 "No se pudieron remover atributos de cuarentena"
fi

# 4. Verificar permisos del driver
echo -e "${YELLOW}4. Verificando permisos del driver...${NC}"
if [ -x "/usr/local/bin/maschine_driver" ]; then
    show_status 0 "Driver tiene permisos de ejecución"
else
    echo -e "${YELLOW}🔧 Asignando permisos de ejecución...${NC}"
    if sudo chmod +x /usr/local/bin/maschine_driver; then
        show_status 0 "Permisos de ejecución asignados"
    else
        show_status 1 "No se pudieron asignar permisos"
    fi
fi

# 5. Verificar owner del driver
echo -e "${YELLOW}5. Verificando propietario del driver...${NC}"
DRIVER_OWNER=$(ls -l /usr/local/bin/maschine_driver | awk '{print $3}')
if [ "$DRIVER_OWNER" = "root" ]; then
    show_status 0 "Driver tiene propietario root"
else
    echo -e "${YELLOW}🔧 Cambiando propietario a root...${NC}"
    if sudo chown root:wheel /usr/local/bin/maschine_driver; then
        show_status 0 "Propietario cambiado a root"
    else
        show_status 1 "No se pudo cambiar propietario"
    fi
fi

# 6. Verificar extensiones del sistema
echo -e "${YELLOW}6. Verificando extensiones del sistema...${NC}"
if [ -d "/System/Library/Extensions" ]; then
    show_status 0 "Directorio de extensiones del sistema encontrado"
else
    show_status 1 "Directorio de extensiones del sistema no encontrado"
fi

# 7. Verificar extensiones de terceros
echo -e "${YELLOW}7. Verificando extensiones de terceros...${NC}"
if [ -d "/Library/Extensions" ]; then
    show_status 0 "Directorio de extensiones de terceros encontrado"
else
    show_status 1 "Directorio de extensiones de terceros no encontrado"
fi

# 8. Verificar kexts cargados
echo -e "${YELLOW}8. Verificando kexts cargados...${NC}"
KEXT_COUNT=$(kextstat | grep -v "Index" | wc -l)
if [ $KEXT_COUNT -gt 0 ]; then
    show_status 0 "Kexts cargados: $KEXT_COUNT"
else
    show_status 1 "No hay kexts cargados"
fi

# 9. Verificar permisos de /usr/local
echo -e "${YELLOW}9. Verificando permisos de /usr/local...${NC}"
if [ -w "/usr/local" ]; then
    show_status 0 "Directorio /usr/local es escribible"
else
    show_status 1 "Directorio /usr/local no es escribible"
fi

# 10. Verificar permisos de /usr/local/bin
echo -e "${YELLOW}10. Verificando permisos de /usr/local/bin...${NC}"
if [ -w "/usr/local/bin" ]; then
    show_status 0 "Directorio /usr/local/bin es escribible"
else
    show_status 1 "Directorio /usr/local/bin no es escribible"
fi

echo ""
echo -e "${BLUE}🔧 Aplicando soluciones adicionales...${NC}"

# 11. Intentar firmar el driver con identidad ad-hoc
echo -e "${YELLOW}11. Firmando driver con identidad ad-hoc...${NC}"
if codesign --force --deep --sign - /usr/local/bin/maschine_driver 2>/dev/null; then
    show_status 0 "Driver firmado con identidad ad-hoc"
else
    show_status 1 "No se pudo firmar el driver"
fi

# 12. Verificar integridad del driver
echo -e "${YELLOW}12. Verificando integridad del driver...${NC}"
if codesign -dv /usr/local/bin/maschine_driver 2>/dev/null; then
    show_status 0 "Integridad del driver verificada"
else
    show_status 1 "No se pudo verificar integridad"
fi

# 13. Crear enlace simbólico alternativo
echo -e "${YELLOW}13. Creando enlace simbólico alternativo...${NC}"
if [ ! -L "/usr/bin/maschine_driver" ]; then
    if sudo ln -sf /usr/local/bin/maschine_driver /usr/bin/maschine_driver; then
        show_status 0 "Enlace simbólico creado en /usr/bin/"
    else
        show_status 1 "No se pudo crear enlace simbólico"
    fi
else
    show_status 0 "Enlace simbólico ya existe"
fi

# 14. Verificar que el driver funciona
echo -e "${YELLOW}14. Verificando funcionamiento del driver...${NC}"
if maschine_driver --help &>/dev/null; then
    show_status 0 "Driver responde correctamente"
else
    show_status 1 "Driver no responde"
fi

echo ""
echo -e "${BLUE}🎯 RESUMEN DE SOLUCIONES APLICADAS${NC}"
echo "========================================"

# Contar éxitos y fallos
success_count=0
total_count=0

# Verificar cada paso
for i in {1..14}; do
    case $i in
        1) if ! sudo spctl --status | grep -q "enabled"; then ((success_count++)); fi ;;
        2) if [ ! -f "/usr/local/bin/maschine_driver" ] || ! xattr -l /usr/local/bin/maschine_driver 2>/dev/null | grep -q "quarantine"; then ((success_count++)); fi ;;
        3) if [ ! -f "." ] || ! xattr -l . 2>/dev/null | grep -q "quarantine"; then ((success_count++)); fi ;;
        4) if [ -x "/usr/local/bin/maschine_driver" ]; then ((success_count++)); fi ;;
        5) if [ "$(ls -l /usr/local/bin/maschine_driver | awk '{print $3}')" = "root" ]; then ((success_count++)); fi ;;
        6) if [ -d "/System/Library/Extensions" ]; then ((success_count++)); fi ;;
        7) if [ -d "/Library/Extensions" ]; then ((success_count++)); fi ;;
        8) if [ $(kextstat | grep -v "Index" | wc -l) -gt 0 ]; then ((success_count++)); fi ;;
        9) if [ -w "/usr/local" ]; then ((success_count++)); fi ;;
        10) if [ -w "/usr/local/bin" ]; then ((success_count++)); fi ;;
        11) if codesign -dv /usr/local/bin/maschine_driver &>/dev/null; then ((success_count++)); fi ;;
        12) if codesign -dv /usr/local/bin/maschine_driver &>/dev/null; then ((success_count++)); fi ;;
        13) if [ -L "/usr/bin/maschine_driver" ]; then ((success_count++)); fi ;;
        14) if maschine_driver --help &>/dev/null; then ((success_count++)); fi ;;
    esac
    ((total_count++))
done

# Mostrar resultado final
echo ""
if [ $success_count -eq $total_count ]; then
    echo -e "${GREEN}🎉 ¡TODOS LOS PROBLEMAS RESUELTOS!${NC}"
    echo -e "${GREEN}✅ El driver debería funcionar correctamente ahora${NC}"
else
    echo -e "${YELLOW}⚠️  ALGUNOS PROBLEMAS PERSISTEN${NC}"
    echo -e "${YELLOW}❌ $success_count de $total_count problemas resueltos${NC}"
fi

echo ""
echo -e "${BLUE}🚀 PRÓXIMOS PASOS:${NC}"
echo "1. Reinicia tu Mac si es necesario"
echo "2. Ejecuta: ./maschine_final_solution.sh"
echo "3. O prueba: ./test_activate_inputs"
echo "4. Si persisten problemas, ejecuta: sudo spctl --master-disable"

echo ""
echo -e "${BLUE}📊 Estadísticas:${NC}"
echo "   • Problemas verificados: $total_count"
echo "   • Problemas resueltos: $success_count"
echo "   • Porcentaje de éxito: $((success_count * 100 / total_count))%"

echo ""
echo "🎹 ========================================="
echo "🎹 FIX LEGACY EXTENSIONS FINALIZADO"
echo "🎹 =========================================" 