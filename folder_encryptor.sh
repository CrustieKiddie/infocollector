#!/bin/bash

################################################################################
# FOLDER ENCRYPTOR - Professional Linux Folder Encryption System
# Version: 1.0.0
# Description: Encrypts/Decrypts folders using OpenSSL AES-256-CBC
# Author: Anmysec
# License: MIT
################################################################################

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="${HOME}/.folder_encryptor"
readonly ENCRYPTED_LIST="${CONFIG_DIR}/encrypted_folders.list"
readonly LOG_FILE="${CONFIG_DIR}/encryption.log"
readonly EXTENSION=".klskv"
readonly ENCRYPTION_ALGO="aes-256-cbc"
readonly PBKDF2_ITERATIONS=100000

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" >> "${LOG_FILE}"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
    log "INFO" "$*"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
    log "SUCCESS" "$*"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
    log "WARNING" "$*"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
    log "ERROR" "$*"
}

print_banner() {
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║           FOLDER ENCRYPTOR - Professional Edition             ║
║                  Secure Folder Encryption System              ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
}

# ============================================================================
# INITIALIZATION
# ============================================================================

init_config() {
    if [[ ! -d "${CONFIG_DIR}" ]]; then
        mkdir -p "${CONFIG_DIR}"
        chmod 700 "${CONFIG_DIR}"
        print_info "Configuration directory created: ${CONFIG_DIR}"
    fi
    
    if [[ ! -f "${ENCRYPTED_LIST}" ]]; then
        touch "${ENCRYPTED_LIST}"
        chmod 600 "${ENCRYPTED_LIST}"
    fi
    
    if [[ ! -f "${LOG_FILE}" ]]; then
        touch "${LOG_FILE}"
        chmod 600 "${LOG_FILE}"
    fi
}

# ============================================================================
# ENCRYPTION FUNCTIONS
# ============================================================================

check_dependencies() {
    local missing_deps=()
    
    for cmd in openssl tar; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        print_info "Install them with: sudo apt-get install ${missing_deps[*]}"
        exit 1
    fi
}

validate_folder() {
    local folder="$1"
    
    if [[ ! -e "${folder}" ]]; then
        print_error "Path does not exist: ${folder}"
        return 1
    fi
    
    if [[ ! -d "${folder}" ]]; then
        print_error "Path is not a directory: ${folder}"
        return 1
    fi
    
    if [[ ! -r "${folder}" ]]; then
        print_error "No read permission for: ${folder}"
        return 1
    fi
    
    return 0
}

get_folder_size() {
    local folder="$1"
    du -sh "${folder}" 2>/dev/null | cut -f1
}

encrypt_folder() {
    local folder_path="$1"
    local password="$2"
    
    # Resolve absolute path
    folder_path="$(realpath "${folder_path}")"
    
    # Validate folder
    if ! validate_folder "${folder_path}"; then
        return 1
    fi
    
    local folder_name="$(basename "${folder_path}")"
    local parent_dir="$(dirname "${folder_path}")"
    local encrypted_file="${parent_dir}/${folder_name}${EXTENSION}"
    local temp_archive="${CONFIG_DIR}/${folder_name}.tar.tmp"
    
    # Check if already encrypted
    if [[ -f "${encrypted_file}" ]]; then
        print_warning "Encrypted file already exists: ${encrypted_file}"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Operation cancelled"
            return 1
        fi
    fi
    
    print_info "Starting encryption of: ${folder_path}"
    print_info "Folder size: $(get_folder_size "${folder_path}")"
    
    # Create tar archive
    print_info "Creating archive..."
    if ! tar -czf "${temp_archive}" -C "${parent_dir}" "${folder_name}" 2>/dev/null; then
        print_error "Failed to create archive"
        rm -f "${temp_archive}"
        return 1
    fi
    
    # Encrypt the archive
    print_info "Encrypting archive with ${ENCRYPTION_ALGO}..."
    if ! echo "${password}" | openssl enc -${ENCRYPTION_ALGO} \
        -salt \
        -pbkdf2 \
        -iter ${PBKDF2_ITERATIONS} \
        -in "${temp_archive}" \
        -out "${encrypted_file}" \
        -pass stdin 2>/dev/null; then
        print_error "Encryption failed"
        rm -f "${temp_archive}" "${encrypted_file}"
        return 1
    fi
    
    # Clean up temporary archive
    rm -f "${temp_archive}"
    
    # Set secure permissions
    chmod 600 "${encrypted_file}"
    
    # Add to encrypted list
    echo "${encrypted_file}|${folder_path}|$(date '+%Y-%m-%d %H:%M:%S')" >> "${ENCRYPTED_LIST}"
    
    print_success "Folder encrypted successfully!"
    print_info "Encrypted file: ${encrypted_file}"
    print_info "Original folder: ${folder_path}"
    
    # Ask to remove original
    echo
    read -p "Remove original folder? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Removing original folder..."
        if rm -rf "${folder_path}"; then
            print_success "Original folder removed"
        else
            print_error "Failed to remove original folder"
        fi
    else
        print_warning "Original folder kept. Remember to delete it manually for security!"
    fi
    
    return 0
}

decrypt_folder() {
    local encrypted_file="$1"
    local password="$2"
    local output_dir="${3:-}"
    
    # Resolve absolute path
    encrypted_file="$(realpath "${encrypted_file}")"
    
    # Validate encrypted file
    if [[ ! -f "${encrypted_file}" ]]; then
        print_error "Encrypted file does not exist: ${encrypted_file}"
        return 1
    fi
    
    if [[ ! "${encrypted_file}" =~ ${EXTENSION}$ ]]; then
        print_error "File does not have ${EXTENSION} extension"
        return 1
    fi
    
    # Determine output directory
    if [[ -z "${output_dir}" ]]; then
        output_dir="$(dirname "${encrypted_file}")"
    fi
    
    local temp_archive="${CONFIG_DIR}/decrypt_temp.tar.tmp"
    
    print_info "Starting decryption of: ${encrypted_file}"
    
    # Decrypt the file
    print_info "Decrypting archive..."
    if ! echo "${password}" | openssl enc -${ENCRYPTION_ALGO} \
        -d \
        -salt \
        -pbkdf2 \
        -iter ${PBKDF2_ITERATIONS} \
        -in "${encrypted_file}" \
        -out "${temp_archive}" \
        -pass stdin 2>/dev/null; then
        print_error "Decryption failed - incorrect password or corrupted file"
        rm -f "${temp_archive}"
        return 1
    fi
    
    # Extract the archive
    print_info "Extracting archive..."
    if ! tar -xzf "${temp_archive}" -C "${output_dir}" 2>/dev/null; then
        print_error "Failed to extract archive"
        rm -f "${temp_archive}"
        return 1
    fi
    
    # Clean up temporary archive
    rm -f "${temp_archive}"
    
    print_success "Folder decrypted successfully!"
    print_info "Output directory: ${output_dir}"
    
    # Ask to remove encrypted file
    echo
    read -p "Remove encrypted file? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Removing encrypted file..."
        if rm -f "${encrypted_file}"; then
            print_success "Encrypted file removed"
            # Remove from list
            sed -i "\|^${encrypted_file}|" "${ENCRYPTED_LIST}"
        else
            print_error "Failed to remove encrypted file"
        fi
    fi
    
    return 0
}

# ============================================================================
# LIST MANAGEMENT
# ============================================================================

list_encrypted_folders() {
    if [[ ! -s "${ENCRYPTED_LIST}" ]]; then
        print_info "No encrypted folders registered"
        return 0
    fi
    
    echo
    echo "═══════════════════════════════════════════════════════════════"
    echo "                    ENCRYPTED FOLDERS LIST"
    echo "═══════════════════════════════════════════════════════════════"
    echo
    
    local count=0
    while IFS='|' read -r enc_file orig_path timestamp; do
        ((count++))
        local exists="✓"
        local color="${GREEN}"
        
        if [[ ! -f "${enc_file}" ]]; then
            exists="✗"
            color="${RED}"
        fi
        
        echo -e "${color}[${count}] ${exists}${NC}"
        echo "    Encrypted: ${enc_file}"
        echo "    Original:  ${orig_path}"
        echo "    Date:      ${timestamp}"
        echo
    done < "${ENCRYPTED_LIST}"
    
    echo "═══════════════════════════════════════════════════════════════"
    echo "Total: ${count} encrypted folder(s)"
    echo
}

# ============================================================================
# INTERACTIVE MENU
# ============================================================================

show_menu() {
    echo
    echo "═══════════════════════════════════════════════════════════════"
    echo "                         MAIN MENU"
    echo "═══════════════════════════════════════════════════════════════"
    echo
    echo "  1) Encrypt a folder"
    echo "  2) Decrypt a folder"
    echo "  3) List encrypted folders"
    echo "  4) Batch encrypt multiple folders"
    echo "  5) Batch decrypt all folders"
    echo "  6) Exit"
    echo
    echo "═══════════════════════════════════════════════════════════════"
    echo
}

interactive_mode() {
    while true; do
        show_menu
        read -p "Select an option [1-6]: " choice
        
        case $choice in
            1)
                echo
                read -p "Enter folder path to encrypt: " folder_path
                read -s -p "Enter password: " password
                echo
                read -s -p "Confirm password: " password2
                echo
                
                if [[ "${password}" != "${password2}" ]]; then
                    print_error "Passwords do not match"
                    continue
                fi
                
                encrypt_folder "${folder_path}" "${password}"
                ;;
            2)
                echo
                read -p "Enter encrypted file path (.klskv): " enc_file
                read -s -p "Enter password: " password
                echo
                
                decrypt_folder "${enc_file}" "${password}"
                ;;
            3)
                list_encrypted_folders
                ;;
            4)
                echo
                print_info "Enter folder paths (one per line, empty line to finish):"
                local folders=()
                while true; do
                    read -p "> " folder
                    [[ -z "${folder}" ]] && break
                    folders+=("${folder}")
                done
                
                if [[ ${#folders[@]} -eq 0 ]]; then
                    print_warning "No folders provided"
                    continue
                fi
                
                read -s -p "Enter password for all folders: " password
                echo
                
                for folder in "${folders[@]}"; do
                    echo
                    encrypt_folder "${folder}" "${password}"
                done
                ;;
            5)
                echo
                read -s -p "Enter password to decrypt all folders: " password
                echo
                
                if [[ ! -s "${ENCRYPTED_LIST}" ]]; then
                    print_info "No encrypted folders to decrypt"
                    continue
                fi
                
                while IFS='|' read -r enc_file orig_path timestamp; do
                    if [[ -f "${enc_file}" ]]; then
                        echo
                        decrypt_folder "${enc_file}" "${password}" "$(dirname "${orig_path}")"
                    fi
                done < "${ENCRYPTED_LIST}"
                ;;
            6)
                print_info "Exiting..."
                exit 0
                ;;
            *)
                print_error "Invalid option"
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

# ============================================================================
# COMMAND LINE INTERFACE
# ============================================================================

show_usage() {
    cat << EOF
Usage: ${SCRIPT_NAME} [OPTIONS] COMMAND

Professional folder encryption system using OpenSSL AES-256-CBC

COMMANDS:
    encrypt <folder>              Encrypt a folder
    decrypt <file.klskv>          Decrypt an encrypted file
    list                          List all encrypted folders
    interactive                   Launch interactive menu

OPTIONS:
    -h, --help                    Show this help message
    -v, --version                 Show version information
    -p, --password <pass>         Provide password (not recommended for security)
    -o, --output <dir>            Output directory for decryption

EXAMPLES:
    ${SCRIPT_NAME} encrypt /path/to/folder
    ${SCRIPT_NAME} decrypt /path/to/folder.klskv
    ${SCRIPT_NAME} list
    ${SCRIPT_NAME} interactive

SECURITY NOTES:
    - Uses AES-256-CBC encryption with PBKDF2 (100,000 iterations)
    - Passwords are never stored, only used for encryption/decryption
    - Encrypted files have .klskv extension
    - Always use strong passwords for maximum security

EOF
}

show_version() {
    echo "Folder Encryptor v1.0.0"
    echo "Professional Linux Folder Encryption System"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    # Initialize
    init_config
    check_dependencies
    
    # Parse arguments
    local command=""
    local target=""
    local password=""
    local output_dir=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -p|--password)
                password="$2"
                shift 2
                ;;
            -o|--output)
                output_dir="$2"
                shift 2
                ;;
            encrypt|decrypt|list|interactive)
                command="$1"
                shift
                if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
                    target="$1"
                    shift
                fi
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Execute command
    case $command in
        encrypt)
            if [[ -z "${target}" ]]; then
                print_error "No folder specified"
                show_usage
                exit 1
            fi
            
            if [[ -z "${password}" ]]; then
                read -s -p "Enter password: " password
                echo
                read -s -p "Confirm password: " password2
                echo
                
                if [[ "${password}" != "${password2}" ]]; then
                    print_error "Passwords do not match"
                    exit 1
                fi
            fi
            
            encrypt_folder "${target}" "${password}"
            ;;
        decrypt)
            if [[ -z "${target}" ]]; then
                print_error "No encrypted file specified"
                show_usage
                exit 1
            fi
            
            if [[ -z "${password}" ]]; then
                read -s -p "Enter password: " password
                echo
            fi
            
            decrypt_folder "${target}" "${password}" "${output_dir}"
            ;;
        list)
            list_encrypted_folders
            ;;
        interactive|"")
            print_banner
            interactive_mode
            ;;
        *)
            print_error "Unknown command: ${command}"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
