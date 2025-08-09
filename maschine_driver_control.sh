#!/bin/bash

# Maschine Driver Control Script
# Uso: ./maschine_driver_control.sh [load|unload|start|stop|status|restart|install|uninstall]

DRIVER_NAME="com.maschine.driver"
DRIVER_PATH="/usr/local/bin/maschine_driver"
SERVICE_PATH="/Library/LaunchDaemons/${DRIVER_NAME}.plist"
LOG_PATH="/var/log/maschine_driver.log"
ERROR_LOG_PATH="/var/log/maschine_driver_error.log"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_help() {
    echo -e "${BLUE}🎹 Maschine Driver Control Script${NC}"
    echo ""
    echo "Uso: $0 [COMANDO]"
    echo ""
    echo "Comandos disponibles:"
    echo "  ${GREEN}load${NC}      - Cargar el driver como servicio del sistema"
    echo "  ${GREEN}unload${NC}    - Descargar el driver del sistema"
    echo "  ${GREEN}start${NC}     - Iniciar el driver manualmente"
    echo "  ${GREEN}stop${NC}      - Detener el driver manualmente"
    echo "  ${GREEN}status${NC}    - Mostrar estado del driver"
    echo "  ${GREEN}restart${NC}   - Reiniciar el driver"
    echo "  ${GREEN}install${NC}   - Instalar el driver como servicio"
    echo "  ${GREEN}uninstall${NC} - Desinstalar el driver del sistema"
    echo "  ${GREEN}logs${NC}      - Mostrar logs del driver"
    echo "  ${GREEN}debug${NC}     - Ejecutar en modo debug"
    echo "  ${GREEN}test${NC}      - Probar conexión del driver"
    echo ""
    echo "Ejemplos:"
    echo "  $0 install    # Instalar como servicio"
    echo "  $0 load       # Cargar el servicio"
    echo "  $0 status     # Verificar estado"
    echo "  $0 unload     # Descargar el servicio"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}❌ Error: Este comando requiere permisos de administrador${NC}"
        echo "Ejecuta con: sudo $0 $1"
        exit 1
    fi
}

check_driver_exists() {
    if [ ! -f "$DRIVER_PATH" ]; then
        echo -e "${RED}❌ Error: Driver no encontrado en $DRIVER_PATH${NC}"
        echo "Ejecuta primero: ./install_and_debug.sh"
        exit 1
    fi
}

install_service() {
    echo -e "${BLUE}🔧 Instalando Maschine Driver como servicio del sistema...${NC}"
    
    check_root "install"
    check_driver_exists
    
    # Crear directorio de logs si no existe
    sudo mkdir -p /var/log
    
    # Copiar archivo de servicio
    sudo cp maschine_driver_service.plist "$SERVICE_PATH"
    
    # Establecer permisos correctos
    sudo chown root:wheel "$SERVICE_PATH"
    sudo chmod 644 "$SERVICE_PATH"
    
    echo -e "${GREEN}✅ Servicio instalado en: $SERVICE_PATH${NC}"
    echo -e "${YELLOW}💡 Para cargar el servicio: $0 load${NC}"
}

uninstall_service() {
    echo -e "${BLUE}🗑️  Desinstalando Maschine Driver del sistema...${NC}"
    
    check_root "uninstall"
    
    # Descargar servicio si está cargado
    if launchctl list | grep -q "$DRIVER_NAME"; then
        echo "Descargando servicio..."
        sudo launchctl unload "$SERVICE_PATH" 2>/dev/null || true
    fi
    
    # Eliminar archivo de servicio
    if [ -f "$SERVICE_PATH" ]; then
        sudo rm "$SERVICE_PATH"
        echo -e "${GREEN}✅ Servicio desinstalado${NC}"
    else
        echo -e "${YELLOW}⚠️  Servicio no estaba instalado${NC}"
    fi
}

load_service() {
    echo -e "${BLUE}📥 Cargando Maschine Driver como servicio...${NC}"
    
    check_root "load"
    check_driver_exists
    
    if [ ! -f "$SERVICE_PATH" ]; then
        echo -e "${RED}❌ Error: Servicio no instalado${NC}"
        echo "Ejecuta primero: $0 install"
        exit 1
    fi
    
    # Cargar el servicio
    sudo launchctl load "$SERVICE_PATH"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Driver cargado como servicio del sistema${NC}"
        echo -e "${YELLOW}💡 Para verificar estado: $0 status${NC}"
    else
        echo -e "${RED}❌ Error al cargar el servicio${NC}"
        exit 1
    fi
}

unload_service() {
    echo -e "${BLUE}📤 Descargando Maschine Driver del sistema...${NC}"
    
    check_root "unload"
    
    if [ ! -f "$SERVICE_PATH" ]; then
        echo -e "${YELLOW}⚠️  Servicio no instalado${NC}"
        return
    fi
    
    # Descargar el servicio
    sudo launchctl unload "$SERVICE_PATH"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Driver descargado del sistema${NC}"
    else
        echo -e "${YELLOW}⚠️  Servicio no estaba cargado${NC}"
    fi
}

start_driver() {
    echo -e "${BLUE}🎹 Iniciando Maschine Driver manualmente...${NC}"
    
    check_driver_exists
    
    # Verificar si ya está ejecutándose
    if pgrep -f "maschine_driver" > /dev/null; then
        echo -e "${YELLOW}⚠️  Driver ya está ejecutándose${NC}"
        return
    fi
    
    # Iniciar en background
    nohup "$DRIVER_PATH" --maschine-mode > "$LOG_PATH" 2> "$ERROR_LOG_PATH" &
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Driver iniciado manualmente (PID: $!)${NC}"
        echo -e "${YELLOW}💡 Logs en: $LOG_PATH${NC}"
    else
        echo -e "${RED}❌ Error al iniciar el driver${NC}"
        exit 1
    fi
}

stop_driver() {
    echo -e "${BLUE}🛑 Deteniendo Maschine Driver...${NC}"
    
    # Buscar proceso del driver
    DRIVER_PID=$(pgrep -f "maschine_driver")
    
    if [ -n "$DRIVER_PID" ]; then
        echo "Deteniendo proceso PID: $DRIVER_PID"
        kill "$DRIVER_PID"
        
        # Esperar a que termine
        sleep 2
        
        if kill -0 "$DRIVER_PID" 2>/dev/null; then
            echo "Forzando terminación..."
            kill -9 "$DRIVER_PID"
        fi
        
        echo -e "${GREEN}✅ Driver detenido${NC}"
    else
        echo -e "${YELLOW}⚠️  Driver no estaba ejecutándose${NC}"
    fi
}

show_status() {
    echo -e "${BLUE}📊 Estado del Maschine Driver:${NC}"
    echo ""
    
    # Verificar si el driver existe
    if [ -f "$DRIVER_PATH" ]; then
        echo -e "${GREEN}✅ Driver instalado en: $DRIVER_PATH${NC}"
    else
        echo -e "${RED}❌ Driver no encontrado${NC}"
    fi
    
    # Verificar servicio
    if [ -f "$SERVICE_PATH" ]; then
        echo -e "${GREEN}✅ Servicio instalado en: $SERVICE_PATH${NC}"
    else
        echo -e "${YELLOW}⚠️  Servicio no instalado${NC}"
    fi
    
    # Verificar si está cargado como servicio
    if launchctl list | grep -q "$DRIVER_NAME"; then
        echo -e "${GREEN}✅ Servicio cargado en el sistema${NC}"
    else
        echo -e "${YELLOW}⚠️  Servicio no cargado${NC}"
    fi
    
    # Verificar si está ejecutándose
    DRIVER_PID=$(pgrep -f "maschine_driver")
    if [ -n "$DRIVER_PID" ]; then
        echo -e "${GREEN}✅ Driver ejecutándose (PID: $DRIVER_PID)${NC}"
    else
        echo -e "${YELLOW}⚠️  Driver no ejecutándose${NC}"
    fi
    
    # Verificar conexión MIDI
    echo ""
    echo -e "${BLUE}🔍 Verificando dispositivos MIDI:${NC}"
    "$DRIVER_PATH" --list-sources 2>/dev/null | head -5
}

show_logs() {
    echo -e "${BLUE}📋 Logs del Maschine Driver:${NC}"
    echo ""
    
    if [ -f "$LOG_PATH" ]; then
        echo -e "${GREEN}📄 Log principal:${NC}"
        tail -20 "$LOG_PATH"
    else
        echo -e "${YELLOW}⚠️  No hay logs principales${NC}"
    fi
    
    echo ""
    
    if [ -f "$ERROR_LOG_PATH" ]; then
        echo -e "${RED}📄 Log de errores:${NC}"
        tail -10 "$ERROR_LOG_PATH"
    else
        echo -e "${YELLOW}⚠️  No hay logs de errores${NC}"
    fi
}

restart_driver() {
    echo -e "${BLUE}🔄 Reiniciando Maschine Driver...${NC}"
    stop_driver
    sleep 2
    start_driver
}

debug_mode() {
    echo -e "${BLUE}🐛 Ejecutando Maschine Driver en modo debug...${NC}"
    check_driver_exists
    "$DRIVER_PATH" --debug
}

test_connection() {
    echo -e "${BLUE}🧪 Probando conexión del Maschine Driver...${NC}"
    check_driver_exists
    "$DRIVER_PATH" --test-connection
}

# Procesar argumentos
case "$1" in
    install)
        install_service
        ;;
    uninstall)
        uninstall_service
        ;;
    load)
        load_service
        ;;
    unload)
        unload_service
        ;;
    start)
        start_driver
        ;;
    stop)
        stop_driver
        ;;
    restart)
        restart_driver
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    debug)
        debug_mode
        ;;
    test)
        test_connection
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}❌ Comando desconocido: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac 