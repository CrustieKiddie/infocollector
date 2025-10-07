# infocollector by anmy
Software for collecting and encrypting files from a computer (sh)

# 🔒 Professional Folder Encryption System for Linux by Anmysec

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Bash-4.0%2B-green.svg)](https://www.gnu.org/software/bash/)
[![OpenSSL](https://img.shields.io/badge/OpenSSL-AES--256-red.svg)](https://www.openssl.org/)

A complete and professional folder encryption system for Linux using **OpenSSL AES-256-CBC** with **PBKDF2** (100,000 iterations). Features automatic decryption at system startup with master password protection.

[🇪🇸 Documentación en Español](README_ES.md)

## ✨ Key Features

- 🔐 **AES-256-CBC Encryption**: Military-grade encryption algorithm
- 🔑 **PBKDF2**: 100,000 iterations for maximum brute-force protection
- 🚀 **Auto-Start**: Prompts for password at system boot
- 📦 **Built-in Compression**: Reduces file size before encryption
- 🎨 **Colorful Interface**: Clear and professional colored output
- 📊 **Logging System**: Complete audit trail of all operations
- 🔄 **Interactive Mode**: Easy-to-use menu for all operations
- 📝 **Folder Management**: List and manage all encrypted folders
- 🛡️ **Custom Extension**: Encrypted files with `.klskv` extension

## 🚀 Quick Start

```bash
# 1. Clone and install
git clone <repository> folder-encryption
cd folder-encryption
chmod +x install.sh
./install.sh

# 2. Encrypt a folder
folder-encrypt encrypt ~/Documents/Secret

# 3. Decrypt a folder
folder-encrypt decrypt ~/Documents/Secret.anmy

# 4. Interactive mode
folder-encrypt interactive
```

## 📦 Requirements

- Linux (any distribution)
- Bash 4.0+
- OpenSSL
- tar

```bash
# Ubuntu/Debian
sudo apt-get install openssl tar

# Fedora/RHEL
sudo dnf install openssl tar

# Arch Linux
sudo pacman -S openssl tar
```

## 📖 Usage

### Interactive Mode

```bash
folder-encrypt interactive
```

### Command Line

```bash
# Encrypt a folder
folder-encrypt encrypt /path/to/folder

# Decrypt a folder
folder-encrypt decrypt /path/to/folder.anmy

# List encrypted folders
folder-encrypt list

# Show help
folder-encrypt --help
```

### Auto-Decrypt at Startup

The system automatically prompts for the master password (default: `12345`) at login and decrypts all registered folders.

```bash
# Change master password
nano ~/.local/bin/folder-decrypt-startup
# Edit: readonly MASTER_PASSWORD="12345"

# Test startup
folder-decrypt-startup --test

# Uninstall startup service
folder-decrypt-startup --uninstall
```

## 🔐 Security

- **AES-256-CBC**: 256-bit encryption, military standard
- **PBKDF2**: Key derivation with 100,000 iterations
- **Random Salt**: Each encryption uses a unique salt
- **No Password Storage**: Passwords are never saved
- **Restrictive Permissions**: Config files with 600 permissions
- **Audit Logs**: Complete logging of all operations

### Best Practices

✅ **DO:**
- Use long, complex passwords (minimum 16 characters)
- Keep backups of important encrypted files
- Change the default master password
- Use different passwords for different folders

❌ **DON'T:**
- Use simple or common passwords
- Leave the default master password (12345)
- Use the `-p` command-line option (stays in history)
- Rely solely on encrypted files without backups

## 📁 Project Structure

```
folder-encryption/
├── folder_encryptor.sh          # Main encryption tool
├── auto_decrypt_startup.sh      # Startup decryption service
├── install.sh                   # Installation script
├── README.md                    # English documentation
├── README_ES.md                 # Spanish documentation
└── test_encryption.sh           # Test suite
```

## 🔧 Configuration

Configuration directory: `~/.folder_encryptor/`

```
~/.folder_encryptor/
├── encrypted_folders.list    # List of encrypted folders
├── encryption.log            # Encryption operations log
├── startup_decrypt.log       # Startup decryption log
└── startup.lock              # Session lock file
```

## 🐛 Troubleshooting

### Missing dependencies
```bash
sudo apt-get install openssl tar
```

### Startup service not working
```bash
folder-decrypt-startup --uninstall
folder-decrypt-startup --install
systemctl --user status folder-decrypt-startup.service
```

### Permission denied
```bash
chmod +x ~/.local/bin/folder-encrypt
chmod +x ~/.local/bin/folder-decrypt-startup
```

## 📊 Examples

### Protect Personal Documents
```bash
folder-encrypt encrypt ~/Documents/Personal
# Password: MySecureP@ssw0rd2024
# Remove original? y
```

### Batch Encrypt Projects
```bash
folder-encrypt interactive
# Select option 4: Batch encrypt
# Enter paths and password
```

### Secure Backup
```bash
mkdir ~/Secure_Backup
cp -r ~/Important_Files ~/Secure_Backup/
folder-encrypt encrypt ~/Secure_Backup
cp ~/Secure_Backup.anmy /media/usb/
```

## 🗑️ Uninstallation

```bash
folder-decrypt-startup --uninstall
rm ~/.local/bin/folder-encrypt
rm ~/.local/bin/folder-decrypt-startup
rm -rf ~/.folder_encryptor
rm ~/.local/share/applications/folder-encryptor.desktop
```

## 📄 License

MIT License - Free for personal and commercial use

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## ⚠️ Important Notes

1. **Lost Passwords**: If you forget the password, there's NO way to recover the data
2. **Corrupted Files**: Always keep backups of important files
3. **Master Password**: Change the default password (12345) immediately
4. **Root Access**: Never run scripts as root

## 📞 Support

For issues or questions:
1. Check this documentation
2. Review logs in `~/.folder_encryptor/`
3. Run in verbose mode for more information

---

**Enjoy secure folder encryption! 🔒** //Anmysec//
