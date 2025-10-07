#!/bin/bash

################################################################################
# INSTALLER - Folder Encryption System Installation Script
# Version: 1.0.0
# Description: Installs and configures the folder encryption system
# Author: Anmysec
# License: MIT
################################################################################

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

print_banner() {
    clear
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║ FOLDER ENCRYPTION SYSTEM by Anmy - INSTALLER v1.0.0           ║
║                                                               ║
║              Professional Security Installation               ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

EOF
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $*"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $*"
}

print_error() {
    echo -e "${RED}[✗]${NC} $*" >&2
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should NOT be run as root"
        print_info "Run as normal user: ./install.sh"
        exit 1
    fi
}

check_dependencies() {
    print_info "Checking dependencies..."
    
    local missing_deps=()
    
    for cmd in openssl tar bash; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        echo
        print_info "Install them with:"
        echo "  Ubuntu/Debian: sudo apt-get install ${missing_deps[*]}"
        echo "  Fedora/RHEL:   sudo dnf install ${missing_deps[*]}"
        echo "  Arch:          sudo pacman -S ${missing_deps[*]}"
        exit 1
    fi
    
    print_success "All dependencies satisfied"
}

install_scripts() {
    print_info "Installing scripts..."
    
    local install_dir="${HOME}/.local/bin"
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Create install directory
    mkdir -p "${install_dir}"
    
    # Copy scripts
    cp "${script_dir}/folder_encryptor.sh" "${install_dir}/folder-encrypt"
    cp "${script_dir}/auto_decrypt_startup.sh" "${install_dir}/folder-decrypt-startup"
    
    # Make executable
    chmod +x "${install_dir}/folder-encrypt"
    chmod +x "${install_dir}/folder-decrypt-startup"
    
    print_success "Scripts installed to ${install_dir}"
    
    # Check if directory is in PATH
    if [[ ":$PATH:" != *":${install_dir}:"* ]]; then
        print_warning "${install_dir} is not in your PATH"
        print_info "Adding to ~/.bashrc..."
        
        echo "" >> "${HOME}/.bashrc"
        echo "# Folder Encryption System" >> "${HOME}/.bashrc"
        echo "export PATH=\"\${HOME}/.local/bin:\${PATH}\"" >> "${HOME}/.bashrc"
        
        print_success "Added to PATH. Run: source ~/.bashrc"
    fi
}

configure_startup() {
    print_info "Configuring startup service..."
    
    local startup_script="${HOME}/.local/bin/folder-decrypt-startup"
    
    if [[ -f "${startup_script}" ]]; then
        bash "${startup_script}" --install
        print_success "Startup service configured"
    else
        print_error "Startup script not found"
        return 1
    fi
}

create_desktop_entry() {
    print_info "Creating desktop entry..."
    
    local desktop_dir="${HOME}/.local/share/applications"
    local desktop_file="${desktop_dir}/folder-encryptor.desktop"
    
    mkdir -p "${desktop_dir}"
    
    cat > "${desktop_file}" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Folder Encryptor
Comment=Encrypt and decrypt folders securely
Exec=${HOME}/.local/bin/folder-encrypt interactive
Icon=folder-lock
Terminal=true
Categories=Utility;Security;
Keywords=encrypt;decrypt;security;folder;
EOF
    
    chmod +x "${desktop_file}"
    
    print_success "Desktop entry created"
}

show_completion_message() {
    echo
    echo "═══════════════════════════════════════════════════════════════"
    print_success "Installation completed successfully!"
    echo "═══════════════════════════════════════════════════════════════"
    echo
    print_info "Available commands:"
    echo "  folder-encrypt              - Main encryption tool"
    echo "  folder-decrypt-startup      - Startup decryption service"
    echo
    print_info "Quick start:"
    echo "  1. Encrypt a folder:"
    echo "     folder-encrypt encrypt /path/to/folder"
    echo
    echo "  2. Launch interactive mode:"
    echo "     folder-encrypt interactive"
    echo
    echo "  3. Decrypt at startup:"
    echo "     Configured automatically - will prompt on next login"
    echo
    print_warning "IMPORTANT SECURITY NOTES:"
    echo "  • Master password is set to: 12345"
    echo "  • Change it in: ~/.local/bin/folder-decrypt-startup"
    echo "  • Look for: MASTER_PASSWORD=\"12345\""
    echo "  • Use strong passwords when encrypting folders"
    echo "  • Keep backups of important encrypted files"
    echo
    print_info "Configuration directory: ~/.folder_encryptor"
    print_info "Logs: ~/.folder_encryptor/encryption.log"
    echo
    echo "═══════════════════════════════════════════════════════════════"
    echo
}

main() {
    print_banner
    
    check_root
    check_dependencies
    
    echo
    read -p "Install Folder Encryption System? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled"
        exit 0
    fi
    
    echo
    install_scripts
    echo
    
    read -p "Configure automatic decryption at startup? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo
        configure_startup
    fi
    
    echo
    create_desktop_entry
    
    show_completion_message
    
    read -p "Would you like to change the master password now? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo
        read -s -p "Enter new master password: " new_pass
        echo
        read -s -p "Confirm new password: " new_pass2
        echo
        
        if [[ "${new_pass}" == "${new_pass2}" ]]; then
            local startup_script="${HOME}/.local/bin/folder-decrypt-startup"
            sed -i "s/^readonly MASTER_PASSWORD=.*/readonly MASTER_PASSWORD=\"${new_pass}\"/" "${startup_script}"
            print_success "Master password updated!"
        else
            print_error "Passwords don't match. Password not changed."
            print_info "You can manually edit: ${HOME}/.local/bin/folder-decrypt-startup"
        fi
    fi
    
    echo
    print_success "Setup complete! Enjoy secure folder encryption!"
    echo
}

main "$@"
