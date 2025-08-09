# 🎹 Rebellion Maschine Driver

Un driver nativo para Maschine Mikro basado en el proyecto [Rebellion](https://github.com/terminar/rebellion), que permite controlar los LEDs y recibir inputs del dispositivo sin necesidad del software oficial de Native Instruments.

## ✨ Características

- ✅ **Control completo de LEDs**: Pads y botones con 17 colores diferentes
- ✅ **Input en tiempo real**: Detección de pads, botones y encoders
- ✅ **Protocolo nativo**: Basado en el protocolo real de Rebellion
- ✅ **Fácil instalación**: Script de instalación automático
- ✅ **Interfaz interactiva**: Comandos simples y claros

## 🚀 Instalación Rápida

```bash
# Clona el repositorio
git clone <tu-repo>
cd maschine-driver

# Instala el driver
./install_rebellion_driver.sh
```

## 📋 Requisitos

- macOS 10.12 o superior
- Xcode Command Line Tools
- Maschine Mikro (MK1, MK2, MK3)

## 🎯 Uso

### Ejecutar el driver
```bash
maschine-rebellion
```

### Test de LEDs
```bash
./test_rebellion_leds.sh
```

## 🎨 Comandos Disponibles

Una vez ejecutado el driver, puedes usar estos comandos:

| Comando | Descripción |
|---------|-------------|
| `test` | Patrón de prueba con diferentes colores |
| `rainbow` | Patrón arcoíris animado |
| `allon` | Encender todos los pads en blanco |
| `alloff` | Apagar todos los LEDs |
| `quit` | Salir del driver |

## 🌈 Colores Disponibles

El driver soporta 17 colores diferentes:

1. **RED** - Rojo
2. **ORANGE** - Naranja
3. **LIGHT_ORANGE** - Naranja claro
4. **WARM_YELLOW** - Amarillo cálido
5. **YELLOW** - Amarillo
6. **LIME** - Lima
7. **GREEN** - Verde
8. **MINT** - Menta
9. **CYAN** - Cian
10. **TURQUOISE** - Turquesa
11. **BLUE** - Azul
12. **PLUM** - Ciruela
13. **VIOLET** - Violeta
14. **PURPLE** - Púrpura
15. **MAGENTA** - Magenta
16. **FUCHSIA** - Fucsia
17. **WHITE** - Blanco

## 🔧 Desarrollo

### Compilar manualmente
```bash
make -f Makefile.rebellion clean
make -f Makefile.rebellion
```

### Estructura del código
- `rebellion_maschine_driver.cpp` - Driver principal
- `Makefile.rebellion` - Makefile para compilación
- `install_rebellion_driver.sh` - Script de instalación
- `test_rebellion_leds.sh` - Script de prueba

## 🎵 Protocolo Rebellion

El driver implementa el protocolo SysEx de Rebellion:

### Control de LEDs de Pads
```
F0 00 20 3C 02 00 00 [pad] [color] [intensity] F7
```

### Control de LEDs de Botones
```
F0 00 20 3C 02 00 01 [button] [color] [intensity] F7
```

Donde:
- `F0/F7` - Delimitadores SysEx
- `00 20 3C` - Manufacturer ID de Native Instruments
- `02` - Device ID para Maschine Mikro
- `00 00` - Comando para pads
- `00 01` - Comando para botones
- `[pad/button]` - Índice del elemento (0-15 para pads, 0-7 para botones)
- `[color]` - Color (1-17)
- `[intensity]` - Intensidad (0-127)

## 🎮 Input Mapping

### Pads
- **MIDI Notes**: 36-51 (C2-E3)
- **Evento**: Note On/Off
- **Velocity**: Presión del pad

### Botones
- **MIDI CC**: 16-23
- **Evento**: Control Change
- **Value**: Estado del botón

### Encoders
- **MIDI CC**: 24-25
- **Evento**: Control Change
- **Value**: Posición del encoder

## 🔍 Solución de Problemas

### El driver no encuentra la Maschine Mikro
1. Verifica que el dispositivo esté conectado por USB
2. Asegúrate de que aparezca en "Audio MIDI Setup"
3. Reinicia el driver

### Los LEDs no se encienden
1. Verifica que el driver esté conectado correctamente
2. Prueba el comando `allon`
3. Revisa los logs del driver

### Inputs no se detectan
1. Presiona algunos pads para verificar
2. Verifica que el dispositivo aparezca como "Maschine Mikro Input"
3. Reinicia el driver

## 📚 Referencias

- [Proyecto Rebellion Original](https://github.com/terminar/rebellion)
- [Documentación CoreMIDI](https://developer.apple.com/documentation/coremidi)
- [Protocolo MIDI SysEx](https://www.midi.org/specifications-old/item/table-4-universal-system-exclusive-messages)

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está basado en Rebellion y mantiene la licencia LGPLv3.

## 🙏 Agradecimientos

- **Björn Kalkbrenner** - Creador del proyecto Rebellion
- **Native Instruments** - Por crear el hardware Maschine Mikro
- **Comunidad MIDI** - Por mantener estándares abiertos

---

**¡Disfruta de tu Maschine Mikro con control total de LEDs! 🎹✨** 