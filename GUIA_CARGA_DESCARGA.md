# 🎹 GUÍA DE CARGA Y DESCARGA - MASCHINE DRIVER

## 📋 **RESUMEN DE OPCIONES DISPONIBLES**

### ✅ **OPCIÓN 1: Driver Manual (Recomendado para desarrollo)**
```bash
# Iniciar driver manualmente
maschine_driver --maschine-mode

# Iniciar en modo debug
maschine_driver --debug

# Iniciar en modo MIDI
maschine_driver --midi-mode

# Modo interactivo completo
maschine_driver
```

### ✅ **OPCIÓN 2: Script de Control (Recomendado para uso diario)**
```bash
# Ver ayuda
./maschine_driver_control.sh help

# Iniciar manualmente
./maschine_driver_control.sh start

# Detener manualmente
./maschine_driver_control.sh stop

# Ver estado
./maschine_driver_control.sh status

# Ver logs
./maschine_driver_control.sh logs

# Reiniciar
./maschine_driver_control.sh restart
```

### ✅ **OPCIÓN 3: Servicio del Sistema (Recomendado para producción)**
```bash
# Instalar como servicio (requiere sudo)
sudo ./maschine_driver_control.sh install

# Cargar servicio
sudo ./maschine_driver_control.sh load

# Descargar servicio
sudo ./maschine_driver_control.sh unload

# Desinstalar servicio
sudo ./maschine_driver_control.sh uninstall
```

### ✅ **OPCIÓN 4: Instalación Completa**
```bash
# Instalación completa con servicio
sudo ./install_driver_complete.sh
```

## 🚀 **FLUJOS DE TRABAJO RECOMENDADOS**

### 🎯 **Para Desarrollo y Testing**
```bash
# 1. Verificar estado
./maschine_driver_control.sh status

# 2. Iniciar en modo debug
maschine_driver --debug

# 3. Probar conexión
maschine_driver --test-connection

# 4. Detener cuando termine
Ctrl+C
```

### 🎯 **Para Uso Diario**
```bash
# 1. Iniciar driver
./maschine_driver_control.sh start

# 2. Verificar que está funcionando
./maschine_driver_control.sh status

# 3. Monitorear logs si es necesario
./maschine_driver_control.sh logs

# 4. Detener cuando termine de usar
./maschine_driver_control.sh stop
```

### 🎯 **Para Configuración Permanente**
```bash
# 1. Instalar como servicio
sudo ./maschine_driver_control.sh install

# 2. Cargar servicio
sudo ./maschine_driver_control.sh load

# 3. Verificar que se carga automáticamente
./maschine_driver_control.sh status

# 4. Para descargar cuando sea necesario
sudo ./maschine_driver_control.sh unload
```

## 🔧 **COMANDOS ESPECÍFICOS DEL DRIVER**

### 📡 **Verificación de Dispositivos**
```bash
# Listar fuentes MIDI
maschine_driver --list-sources

# Listar destinos MIDI
maschine_driver --list-destinations

# Probar conexión
maschine_driver --test-connection
```

### 🐛 **Modos de Debug**
```bash
# Modo debug interactivo
maschine_driver --debug

# Modo Maschine nativo
maschine_driver --maschine-mode

# Modo MIDI estándar
maschine_driver --midi-mode
```

### 📊 **Monitoreo y Logs**
```bash
# Ver logs del driver
./maschine_driver_control.sh logs

# Ver estado completo
./maschine_driver_control.sh status

# Ver logs del sistema
tail -f /var/log/maschine_driver.log
```

## ⚠️ **SOLUCIÓN DE PROBLEMAS**

### 🔍 **Driver No Se Inicia**
```bash
# 1. Verificar que está instalado
ls -la /usr/local/bin/maschine_driver

# 2. Verificar permisos
chmod +x /usr/local/bin/maschine_driver

# 3. Probar ejecución directa
/usr/local/bin/maschine_driver --help
```

### 🔍 **Servicio No Se Carga**
```bash
# 1. Verificar archivo de servicio
ls -la /Library/LaunchDaemons/com.maschine.driver.plist

# 2. Verificar permisos del servicio
sudo chown root:wheel /Library/LaunchDaemons/com.maschine.driver.plist
sudo chmod 644 /Library/LaunchDaemons/com.maschine.driver.plist

# 3. Intentar cargar manualmente
sudo launchctl load /Library/LaunchDaemons/com.maschine.driver.plist
```

### 🔍 **Procesos Residuales**
```bash
# 1. Buscar procesos del driver
ps aux | grep maschine_driver

# 2. Detener todos los procesos
pkill -f maschine_driver

# 3. Verificar que no quedan procesos
ps aux | grep maschine_driver
```

### 🔍 **Problemas de Permisos**
```bash
# 1. Crear directorio de logs con permisos correctos
sudo mkdir -p /var/log
sudo chmod 755 /var/log

# 2. Crear archivo de log con permisos correctos
sudo touch /var/log/maschine_driver.log
sudo chmod 666 /var/log/maschine_driver.log
```

## 📁 **ARCHIVOS IMPORTANTES**

### 🔧 **Archivos del Driver**
- `/usr/local/bin/maschine_driver` - Driver principal
- `/usr/local/bin/maschine_control` - Script de control
- `/Library/LaunchDaemons/com.maschine.driver.plist` - Servicio del sistema

### 📄 **Archivos de Logs**
- `/var/log/maschine_driver.log` - Log principal
- `/var/log/maschine_driver_error.log` - Log de errores

### 🛠️ **Archivos de Configuración**
- `maschine_driver_service.plist` - Configuración del servicio
- `maschine_driver_control.sh` - Script de control
- `install_driver_complete.sh` - Script de instalación completa

## 🎯 **RECOMENDACIONES**

### ✅ **Para Desarrollo**
- Usar modo manual con `maschine_driver --debug`
- Monitorear logs en tiempo real
- Usar `Ctrl+C` para detener

### ✅ **Para Uso Diario**
- Usar script de control: `./maschine_driver_control.sh start/stop`
- Verificar estado antes de usar
- Monitorear logs si hay problemas

### ✅ **Para Configuración Permanente**
- Instalar como servicio del sistema
- Configurar para que se inicie automáticamente
- Usar comandos de carga/descarga del servicio

## 🎉 **CONCLUSIÓN**

El driver de Maschine Mikro MK1 ofrece **múltiples opciones de carga y descarga** para adaptarse a diferentes necesidades:

- **🎯 Manual**: Para desarrollo y testing
- **🎛️ Script de Control**: Para uso diario
- **🔧 Servicio del Sistema**: Para configuración permanente

**¡Elige la opción que mejor se adapte a tu flujo de trabajo!** 