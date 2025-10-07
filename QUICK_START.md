# 🚀 Guía de Inicio Rápido - Sistema de Encriptación de Carpetas

## ⚡ Instalación en 3 Pasos

### 1️⃣ Preparar los Scripts

```bash
# Navegar al directorio
cd /ruta/donde/descargaste/los/scripts

# Dar permisos de ejecución
chmod +x install.sh folder_encryptor.sh auto_decrypt_startup.sh test_encryption.sh
```

### 2️⃣ Instalar el Sistema

```bash
# Ejecutar el instalador
./install.sh

# Seguir las instrucciones en pantalla
# - Confirmar instalación: y
# - Configurar inicio automático: y
# - Cambiar contraseña maestra: y (RECOMENDADO)
```

### 3️⃣ Verificar la Instalación

```bash
# Ejecutar pruebas
./test_encryption.sh

# Si todo está bien, verás: ✓ ALL TESTS PASSED!
```

## 📝 Uso Básico

### Encriptar una Carpeta

```bash
# Método 1: Comando directo
folder-encrypt encrypt ~/Documentos/MiCarpetaSecreta

# Método 2: Modo interactivo (más fácil)
folder-encrypt interactive
# Luego selecciona opción 1
```

### Desencriptar una Carpeta

```bash
# Método 1: Comando directo
folder-encrypt decrypt ~/Documentos/MiCarpetaSecreta.anmy

# Método 2: Modo interactivo
folder-encrypt interactive
# Luego selecciona opción 2
```

### Ver Carpetas Encriptadas

```bash
folder-encrypt list
```

## 🔐 Configuración del Inicio Automático

### ¿Cómo Funciona?

1. **Al iniciar sesión** en tu sistema Linux
2. **Aparece un prompt** pidiendo la contraseña maestra
3. **Si es correcta**, desencripta todas las carpetas automáticamente
4. **Si fallas 3 veces**, las carpetas permanecen encriptadas

### Cambiar la Contraseña Maestra

```bash
# Editar el script
nano ~/.local/bin/folder-decrypt-startup

# Buscar esta línea (aproximadamente línea 25):
readonly MASTER_PASSWORD="12345"

# Cambiar por tu contraseña segura:
readonly MASTER_PASSWORD="MiContraseñaSuperSegura2024!"

# Guardar: Ctrl+O, Enter
# Salir: Ctrl+X
```

### Probar el Sistema de Inicio

```bash
# Probar sin bloqueo de sesión
folder-decrypt-startup --test

# Simular inicio de sesión completo
folder-decrypt-startup --startup
```

## 🎯 Ejemplo Completo Paso a Paso

### Escenario: Proteger Documentos Personales

```bash
# 1. Crear una carpeta con archivos sensibles
mkdir ~/Documentos/Confidencial
echo "Información secreta" > ~/Documentos/Confidencial/secreto.txt
echo "Contraseñas" > ~/Documentos/Confidencial/passwords.txt

# 2. Encriptar la carpeta
folder-encrypt encrypt ~/Documentos/Confidencial
# Contraseña: MiPassword123!
# Confirmar: MiPassword123!
# ¿Eliminar original? y

# 3. Verificar que se creó el archivo encriptado
ls -lh ~/Documentos/Confidencial.anmy

# 4. Listar carpetas encriptadas
folder-encrypt list

# 5. Desencriptar cuando necesites acceder
folder-encrypt decrypt ~/Documentos/Confidencial.anmy
# Contraseña: MiPassword123!
# ¿Eliminar archivo encriptado? n (mantenerlo por seguridad)

# 6. Usar los archivos
cat ~/Documentos/Confidencial/secreto.txt

# 7. Volver a encriptar cuando termines
folder-encrypt encrypt ~/Documentos/Confidencial
```

## 🔥 Comandos Más Usados

```bash
# Modo interactivo (recomendado para principiantes)
folder-encrypt interactive

# Encriptar carpeta
folder-encrypt encrypt /ruta/carpeta

# Desencriptar archivo
folder-encrypt decrypt /ruta/archivo.anmy

# Ver lista de carpetas encriptadas
folder-encrypt list

# Ver ayuda
folder-encrypt --help

# Probar inicio automático
folder-decrypt-startup --test

# Desinstalar inicio automático
folder-decrypt-startup --uninstall
```

## ⚙️ Configuración Avanzada

### Ubicación de Archivos

```bash
# Scripts instalados
~/.local/bin/folder-encrypt
~/.local/bin/folder-decrypt-startup

# Configuración
~/.folder_encryptor/encrypted_folders.list
~/.folder_encryptor/encryption.log
~/.folder_encryptor/startup_decrypt.log

# Servicio systemd
~/.config/systemd/user/folder-decrypt-startup.service
```

### Ver Logs

```bash
# Log de encriptación
tail -f ~/.folder_encryptor/encryption.log

# Log de inicio automático
tail -f ~/.folder_encryptor/startup_decrypt.log

# Log del servicio systemd
journalctl --user -u folder-decrypt-startup.service
```

### Gestionar el Servicio

```bash
# Ver estado
systemctl --user status folder-decrypt-startup.service

# Iniciar manualmente
systemctl --user start folder-decrypt-startup.service

# Detener
systemctl --user stop folder-decrypt-startup.service

# Deshabilitar
systemctl --user disable folder-decrypt-startup.service

# Habilitar
systemctl --user enable folder-decrypt-startup.service
```

## 🛡️ Consejos de Seguridad

### ✅ HACER

1. **Usar contraseñas fuertes**
   ```
   ❌ Débil: password123
   ✅ Fuerte: Tr4b4j0$3gur0#2024!
   ```

2. **Cambiar la contraseña maestra por defecto**
   ```bash
   nano ~/.local/bin/folder-decrypt-startup
   # Cambiar: readonly MASTER_PASSWORD="12345"
   ```

3. **Mantener backups**
   ```bash
   # Copiar archivos encriptados a USB
   cp ~/Documentos/*.anmy /media/usb/backup/
   ```

4. **Verificar encriptación**
   ```bash
   # El archivo debe ser binario/data
   file ~/Documentos/Confidencial.anmy
   # Salida: data
   ```

### ❌ NO HACER

1. **No usar contraseñas en línea de comandos**
   ```bash
   # ❌ MALO (queda en historial)
   folder-encrypt encrypt /carpeta -p "password123"
   
   # ✅ BUENO (solicita contraseña)
   folder-encrypt encrypt /carpeta
   ```

2. **No dejar la contraseña maestra por defecto**
   ```bash
   # Cambiarla inmediatamente después de instalar
   ```

3. **No confiar solo en archivos encriptados**
   ```bash
   # Siempre mantener backups en múltiples ubicaciones
   ```

## 🐛 Solución de Problemas Comunes

### Problema: "Command not found"

```bash
# Solución: Agregar al PATH
echo 'export PATH="${HOME}/.local/bin:${PATH}"' >> ~/.bashrc
source ~/.bashrc
```

### Problema: "Permission denied"

```bash
# Solución: Dar permisos de ejecución
chmod +x ~/.local/bin/folder-encrypt
chmod +x ~/.local/bin/folder-decrypt-startup
```

### Problema: "Decryption failed"

```bash
# Causa: Contraseña incorrecta o archivo corrupto
# Solución: Verificar contraseña o restaurar desde backup
```

### Problema: El inicio automático no funciona

```bash
# Reinstalar el servicio
folder-decrypt-startup --uninstall
folder-decrypt-startup --install

# Verificar estado
systemctl --user status folder-decrypt-startup.service
```

## 📞 Obtener Ayuda

```bash
# Ayuda del comando principal
folder-encrypt --help

# Ayuda del inicio automático
folder-decrypt-startup --help

# Ver versión
folder-encrypt --version

# Ejecutar pruebas
./test_encryption.sh
```

## 🎓 Recursos Adicionales

- **Documentación completa en español**: [README_ES.md](README_ES.md)
- **English documentation**: [README.md](README.md)
- **Logs del sistema**: `~/.folder_encryptor/`

## ✨ Características Destacadas

- 🔐 **AES-256-CBC**: Encriptación de grado militar
- 🔑 **PBKDF2**: 100,000 iteraciones contra fuerza bruta
- 🚀 **Inicio automático**: Desencripta al iniciar sesión
- 📦 **Compresión**: Reduce tamaño antes de encriptar
- 🎨 **Interfaz colorida**: Fácil de usar
- 📊 **Logs completos**: Auditoría de todas las operaciones

## 🎉 ¡Listo para Usar!

Ya tienes todo configurado. Comienza protegiendo tus archivos:

```bash
# Modo interactivo (recomendado)
folder-encrypt interactive

# O encripta directamente
folder-encrypt encrypt ~/Documentos/MiCarpetaSecreta
```

---

**¡Disfruta de la seguridad profesional para tus carpetas! 🔒**
