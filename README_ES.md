# 🔒 Sistema Profesional de Encriptación de Carpetas para Linux

## 📋 Descripción

Sistema completo y profesional de encriptación de carpetas para Linux que utiliza **OpenSSL AES-256-CBC** con **PBKDF2** (100,000 iteraciones). Incluye desencriptación automática al inicio del sistema mediante contraseña maestra.

## ✨ Características Principales

- 🔐 **Encriptación AES-256-CBC**: Algoritmo de encriptación de grado militar
- 🔑 **PBKDF2**: 100,000 iteraciones para máxima seguridad contra ataques de fuerza bruta
- 🚀 **Inicio Automático**: Solicita contraseña al arrancar el sistema
- 📦 **Compresión Integrada**: Reduce el tamaño de archivos antes de encriptar
- 🎨 **Interfaz Colorida**: Salida clara y profesional con códigos de color
- 📊 **Sistema de Logs**: Registro completo de todas las operaciones
- 🔄 **Modo Interactivo**: Menú fácil de usar para todas las operaciones
- 📝 **Gestión de Carpetas**: Lista y administra todas las carpetas encriptadas
- 🛡️ **Extensión Personalizada**: Archivos encriptados con extensión `.klskv`

## 🎯 Casos de Uso

- Proteger documentos confidenciales
- Asegurar datos personales sensibles
- Encriptar carpetas de trabajo antes de apagar el equipo
- Proteger información en equipos compartidos
- Backup seguro de archivos importantes

## 📦 Requisitos del Sistema

### Sistema Operativo
- Linux (cualquier distribución)
- Bash 4.0 o superior

### Dependencias
```bash
# Ubuntu/Debian
sudo apt-get install openssl tar

# Fedora/RHEL/CentOS
sudo dnf install openssl tar

# Arch Linux
sudo pacman -S openssl tar
```

## 🚀 Instalación

### Instalación Automática (Recomendada)

```bash
# 1. Descargar los scripts
cd ~
git clone <repositorio> folder-encryption
cd folder-encryption

# 2. Dar permisos de ejecución
chmod +x install.sh folder_encryptor.sh auto_decrypt_startup.sh

# 3. Ejecutar instalador
./install.sh
```

El instalador realizará:
- ✅ Verificación de dependencias
- ✅ Instalación de scripts en `~/.local/bin`
- ✅ Configuración del PATH
- ✅ Instalación del servicio de inicio automático
- ✅ Creación de entrada en el menú de aplicaciones

### Instalación Manual

```bash
# 1. Copiar scripts
mkdir -p ~/.local/bin
cp folder_encryptor.sh ~/.local/bin/folder-encrypt
cp auto_decrypt_startup.sh ~/.local/bin/folder-decrypt-startup
chmod +x ~/.local/bin/folder-encrypt
chmod +x ~/.local/bin/folder-decrypt-startup

# 2. Agregar al PATH
echo 'export PATH="${HOME}/.local/bin:${PATH}"' >> ~/.bashrc
source ~/.bashrc

# 3. Instalar servicio de inicio
folder-decrypt-startup --install
```

## 📖 Uso

### Modo Interactivo (Recomendado para Principiantes)

```bash
folder-encrypt interactive
```

Esto abrirá un menú con las siguientes opciones:
```
1) Encriptar una carpeta
2) Desencriptar una carpeta
3) Listar carpetas encriptadas
4) Encriptar múltiples carpetas
5) Desencriptar todas las carpetas
6) Salir
```

### Línea de Comandos

#### Encriptar una Carpeta

```bash
# Modo interactivo (solicita contraseña)
folder-encrypt encrypt /ruta/a/carpeta

# Con contraseña en línea (NO RECOMENDADO - queda en historial)
folder-encrypt encrypt /ruta/a/carpeta -p "mi_contraseña"
```

**Ejemplo:**
```bash
$ folder-encrypt encrypt ~/Documentos/Confidencial
Enter password: ********
Confirm password: ********
[INFO] Starting encryption of: /home/user/Documentos/Confidencial
[INFO] Folder size: 150M
[INFO] Creating archive...
[INFO] Encrypting archive with aes-256-cbc...
[SUCCESS] Folder encrypted successfully!
[INFO] Encrypted file: /home/user/Documentos/Confidencial.klskv
Remove original folder? (y/N):
```

#### Desencriptar una Carpeta

```bash
# Modo interactivo
folder-encrypt decrypt /ruta/a/carpeta.klskv

# Especificar directorio de salida
folder-encrypt decrypt /ruta/a/carpeta.klskv -o /ruta/destino
```

**Ejemplo:**
```bash
$ folder-encrypt decrypt ~/Documentos/Confidencial.klskv
Enter password: ********
[INFO] Starting decryption of: /home/user/Documentos/Confidencial.klskv
[INFO] Decrypting archive...
[INFO] Extracting archive...
[SUCCESS] Folder decrypted successfully!
Remove encrypted file? (y/N):
```

#### Listar Carpetas Encriptadas

```bash
folder-encrypt list
```

**Salida:**
```
═══════════════════════════════════════════════════════════════
                    ENCRYPTED FOLDERS LIST
═══════════════════════════════════════════════════════════════

[1] ✓
    Encrypted: /home/user/Documentos/Confidencial.klskv
    Original:  /home/user/Documentos/Confidencial
    Date:      2024-01-15 10:30:45

[2] ✓
    Encrypted: /home/user/Proyectos/Secreto.klskv
    Original:  /home/user/Proyectos/Secreto
    Date:      2024-01-15 11:20:30

═══════════════════════════════════════════════════════════════
Total: 2 encrypted folder(s)
```

### Sistema de Inicio Automático

#### Funcionamiento

1. Al iniciar sesión en Linux, el sistema ejecuta automáticamente el script
2. Aparece un prompt solicitando la contraseña maestra (por defecto: `12345`)
3. Si la contraseña es correcta, desencripta todas las carpetas registradas
4. Si falla 3 veces, las carpetas permanecen encriptadas

#### Cambiar la Contraseña Maestra

```bash
# Editar el script
nano ~/.local/bin/folder-decrypt-startup

# Buscar la línea:
readonly MASTER_PASSWORD="12345"

# Cambiar por tu contraseña:
readonly MASTER_PASSWORD="tu_contraseña_segura"
```

#### Probar el Sistema de Inicio

```bash
# Probar sin bloqueo
folder-decrypt-startup --test

# Simular inicio de sesión
folder-decrypt-startup --startup
```

#### Desinstalar el Inicio Automático

```bash
folder-decrypt-startup --uninstall
```

## 🔧 Configuración Avanzada

### Archivos de Configuración

```
~/.folder_encryptor/
├── encrypted_folders.list    # Lista de carpetas encriptadas
├── encryption.log            # Log de operaciones de encriptación
├── startup_decrypt.log       # Log de desencriptación al inicio
└── startup.lock              # Archivo de bloqueo de sesión
```

### Cambiar Algoritmo de Encriptación

Editar `folder_encryptor.sh`:
```bash
readonly ENCRYPTION_ALGO="aes-256-cbc"  # Cambiar a: aes-256-gcm, etc.
readonly PBKDF2_ITERATIONS=100000       # Aumentar para más seguridad
```

### Personalizar Extensión de Archivos

```bash
readonly EXTENSION=".klskv"  # Cambiar a tu extensión preferida
```

## 🔐 Seguridad

### Características de Seguridad

1. **AES-256-CBC**: Encriptación de 256 bits, estándar militar
2. **PBKDF2**: Derivación de clave con 100,000 iteraciones
3. **Salt Aleatorio**: Cada encriptación usa un salt único
4. **Sin Almacenamiento de Contraseñas**: Las contraseñas nunca se guardan
5. **Permisos Restrictivos**: Archivos de configuración con permisos 600
6. **Logs de Auditoría**: Registro completo de todas las operaciones

### Mejores Prácticas

✅ **HACER:**
- Usar contraseñas largas y complejas (mínimo 16 caracteres)
- Mantener backups de archivos encriptados importantes
- Cambiar la contraseña maestra por defecto
- Verificar la integridad de archivos encriptados regularmente
- Usar diferentes contraseñas para diferentes carpetas

❌ **NO HACER:**
- Usar contraseñas simples o comunes
- Compartir contraseñas por medios inseguros
- Dejar la contraseña maestra por defecto (12345)
- Confiar únicamente en archivos encriptados sin backups
- Usar la opción `-p` en línea de comandos (queda en historial)

### Recomendaciones de Contraseñas

```
❌ Débil:     password123
❌ Débil:     12345678
⚠️  Media:    MiContraseña2024
✅ Fuerte:   Tr4b4j0$3gur0#2024!
✅ Muy Fuerte: kL9#mP2$vN8@qR5&wT3^xY7*
```

## 🐛 Solución de Problemas

### Error: "Missing required dependencies"

```bash
# Instalar dependencias faltantes
sudo apt-get install openssl tar  # Ubuntu/Debian
sudo dnf install openssl tar      # Fedora/RHEL
```

### Error: "Decryption failed - incorrect password"

- Verificar que la contraseña sea correcta
- Asegurarse de que el archivo no esté corrupto
- Intentar con el archivo original si tienes backup

### Error: "Permission denied"

```bash
# Dar permisos de ejecución
chmod +x ~/.local/bin/folder-encrypt
chmod +x ~/.local/bin/folder-decrypt-startup
```

### El inicio automático no funciona

```bash
# Reinstalar el servicio
folder-decrypt-startup --uninstall
folder-decrypt-startup --install

# Verificar el servicio
systemctl --user status folder-decrypt-startup.service

# Ver logs
journalctl --user -u folder-decrypt-startup.service
```

### Carpetas no se desencriptan al inicio

1. Verificar que las carpetas estén en la lista:
   ```bash
   folder-encrypt list
   ```

2. Verificar que los archivos `.klskv` existan

3. Probar desencriptación manual:
   ```bash
   folder-encrypt decrypt /ruta/archivo.klskv
   ```

## 📊 Ejemplos de Uso Completos

### Ejemplo 1: Proteger Documentos Personales

```bash
# 1. Encriptar carpeta de documentos
folder-encrypt encrypt ~/Documentos/Personal
# Contraseña: MiContraseña$egura2024

# 2. Eliminar carpeta original cuando se pregunte
Remove original folder? (y/N): y

# 3. Verificar encriptación
folder-encrypt list

# 4. Al reiniciar el sistema, se solicitará la contraseña maestra
# y la carpeta se desencriptará automáticamente
```

### Ejemplo 2: Encriptar Múltiples Proyectos

```bash
# Modo interactivo
folder-encrypt interactive

# Seleccionar opción 4: Batch encrypt multiple folders
# Ingresar rutas:
> ~/Proyectos/Proyecto1
> ~/Proyectos/Proyecto2
> ~/Proyectos/Proyecto3
> [Enter para finalizar]

# Ingresar contraseña única para todos
Enter password for all folders: ********
```

### Ejemplo 3: Backup Seguro

```bash
# 1. Crear carpeta de backup
mkdir ~/Backup_Seguro

# 2. Copiar archivos importantes
cp -r ~/Documentos/Importantes ~/Backup_Seguro/

# 3. Encriptar el backup
folder-encrypt encrypt ~/Backup_Seguro

# 4. Copiar archivo encriptado a USB o nube
cp ~/Backup_Seguro.klskv /media/usb/
```

## 🔄 Actualización

```bash
# Descargar nueva versión
cd ~/folder-encryption
git pull

# Reinstalar
./install.sh
```

## 🗑️ Desinstalación

```bash
# 1. Desinstalar servicio de inicio
folder-decrypt-startup --uninstall

# 2. Eliminar scripts
rm ~/.local/bin/folder-encrypt
rm ~/.local/bin/folder-decrypt-startup

# 3. Eliminar configuración (CUIDADO: perderás la lista de carpetas)
rm -rf ~/.folder_encryptor

# 4. Eliminar entrada del menú
rm ~/.local/share/applications/folder-encryptor.desktop

# 5. Limpiar PATH en ~/.bashrc (opcional)
# Editar manualmente y eliminar la línea de export PATH
```

## 📝 Notas Importantes

⚠️ **ADVERTENCIAS:**

1. **Contraseñas Olvidadas**: Si olvidas la contraseña, NO hay forma de recuperar los datos
2. **Archivos Corruptos**: Mantén siempre backups de archivos importantes
3. **Contraseña Maestra**: Cambia la contraseña por defecto (12345) inmediatamente
4. **Historial de Bash**: Evita usar `-p` en línea de comandos
5. **Permisos**: No ejecutes los scripts como root

## 🤝 Contribuciones

Este es un proyecto profesional de código abierto. Las contribuciones son bienvenidas:

- Reportar bugs
- Sugerir nuevas características
- Mejorar la documentación
- Enviar pull requests

## 📄 Licencia

MIT License - Uso libre para proyectos personales y comerciales

## 👨‍💻 Autor

Script profesional de seguridad para Linux

## 📞 Soporte

Para problemas o preguntas:
1. Revisar esta documentación
2. Verificar los logs en `~/.folder_encryptor/`
3. Ejecutar en modo verbose para más información

## 🎓 Recursos Adicionales

- [OpenSSL Documentation](https://www.openssl.org/docs/)
- [AES Encryption Standard](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard)
- [PBKDF2 Key Derivation](https://en.wikipedia.org/wiki/PBKDF2)

---

**¡Disfruta de la encriptación segura de tus carpetas! 🔒** //Anmysec//
