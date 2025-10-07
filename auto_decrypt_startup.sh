#!/bin/bash

################################################################################
# AUTO DECRYPT STARTUP - System Boot Decryption Service
# Version: 1.0.0
# Description: Automatically prompts for password at system startup
#              and decrypts all registered folders
# Author: Anmysec
# License: MIT
################################################################################

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

readonly SCRIPT_NAME="$(basename "$0")"
readonly CONFIG_DIR="${HOME}/.folder_encryptor"
readonly ENCRYPTED_LIST="${CONFIG_DIR}/encrypted_folders.list"
readonly LOG_FILE="${CONFIG_DIR}/startup_decrypt.log"
readonly LOCK_FILE="${CONFIG_DIR}/startup.lock"
readonly EXTENSION=".klskv"
readonly ENCRYPTION_ALGO="aes-256-cbc"
readonly PBKDF2_ITERATIONS=100000
readonly MASTER_PASSWORD="12345"
readonly MAX_ATTEMPTS=3

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
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
    echo -e "${GREEN}[✓]${NC} $*"
    log "SUCCESS" "$*"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $*"
    log "WARNING" "$*"
}

print_error() {
    echo -e "${RED}[✗]${NC} $*" >&2
    log "ERROR" "$*"
}

print_banner() {
    clear
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║              🔒 SECURE FOLDER DECRYPTION SYSTEM 🔒            ║
║                                                               ║
║                    System Startup Protection                  ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

EOF
}

# ============================================================================
# LOCK FILE MANAGEMENT
# ============================================================================

create_lock() {
    if [[ -f "${LOCK_FILE}" ]]; then
        local lock_time=$(stat -c %Y "${LOCK_FILE}" 2>/dev/null || echo 0)
        local current_time=$(date +%s)
        local diff=$((current_time - lock_time))
        
        # If lock is older than 1 hour, remove it
        if [[ $diff -gt 3600 ]]; then
            rm -f "${LOCK_FILE}"
        else
            print_warning "Decryption already performed in this session"
            return 1
        fi
    fi
    
    touch "${LOCK_FILE}"
    return 0
}

remove_lock() {
    rm -f "${LOCK_FILE}"
}

# ============================================================================
# DECRYPTION FUNCTIONS
# ============================================================================

decrypt_file_silent() {
    local encrypted_file="$1"
    local password="$2"
    local output_dir="$3"
    
    local temp_archive="${CONFIG_DIR}/decrypt_temp_$$.tar.tmp"
    
    # Decrypt the file
    if ! echo "${password}" | openssl enc -${ENCRYPTION_ALGO} \
        -d \
        -salt \
        -pbkdf2 \
        -iter ${PBKDF2_ITERATIONS} \
        -in "${encrypted_file}" \
        -out "${temp_archive}" \
        -pass stdin 2>/dev/null; then
        rm -f "${temp_archive}"
        return 1
    fi
    
    # Extract the archive
    if ! tar -xzf "${temp_archive}" -C "${output_dir}" 2>/dev/null; then
        rm -f "${temp_archive}"
        return 1
    fi
    
    # Clean up
    rm -f "${temp_archive}"
    return 0
}

decrypt_all_folders() {
    local password="$1"
    
    if [[ ! -f "${ENCRYPTED_LIST}" ]] || [[ ! -s "${ENCRYPTED_LIST}" ]]; then
        print_info "No encrypted folders found"
        return 0
    fi
    
    local total=0
    local success=0
    local failed=0
    
    # Count total
    total=$(wc -l < "${ENCRYPTED_LIST}")
    
    echo
    print_info "Found ${total} encrypted folder(s)"
    echo
    
    while IFS='|' read -r enc_file orig_path timestamp; do
        if [[ ! -f "${enc_file}" ]]; then
            print_warning "Encrypted file not found: ${enc_file}"
            ((failed++))
            continue
        fi
        
        local folder_name=$(basename "${orig_path}")
        echo -ne "${CYAN}[DECRYPTING]${NC} ${folder_name}... "
        
        local output_dir=$(dirname "${orig_path}")
        
        if decrypt_file_silent "${enc_file}" "${password}" "${output_dir}"; then
            echo -e "${GREEN}✓${NC}"
            ((success++))
            log "SUCCESS" "Decrypted: ${enc_file} -> ${orig_path}"
        else
            echo -e "${RED}✗${NC}"
            ((failed++))
            log "ERROR" "Failed to decrypt: ${enc_file}"
        fi
    done < "${ENCRYPTED_LIST}"
    
    echo
    echo "═══════════════════════════════════════════════════════════════"
    print_success "Decryption completed: ${success}/${total} successful"
    if [[ $failed -gt 0 ]]; then
        print_warning "${failed} folder(s) failed to decrypt"
    fi
    echo "═══════════════════════════════════════════════════════════════"
    echo
}

# ============================================================================
# PASSWORD VERIFICATION
# ============================================================================

verify_password() {
    local attempt=1
    
    while [[ $attempt -le $MAX_ATTEMPTS ]]; do
        echo
        read -s -p "🔑 Enter master password to decrypt folders: " input_password
        echo
        
        if [[ "${input_password}" == "${MASTER_PASSWORD}" ]]; then
            return 0
        else
            ((attempt++))
            if [[ $attempt -le $MAX_ATTEMPTS ]]; then
                print_error "Incorrect password. Attempt ${attempt}/${MAX_ATTEMPTS}"
            fi
        fi
    done
    
    return 1
}

# ============================================================================
# MAIN STARTUP ROUTINE
# ============================================================================

startup_routine() {
    print_banner
    
    # Check if config directory exists
    if [[ ! -d "${CONFIG_DIR}" ]]; then
        print_info "No encrypted folders configured"
        print_info "Use 'folder_encryptor.sh' to encrypt folders"
        return 0
    fi
    
    # Check if already decrypted in this session
    if ! create_lock; then
        return 0
    fi
    
    # Check if there are encrypted folders
    if [[ ! -f "${ENCRYPTED_LIST}" ]] || [[ ! -s "${ENCRYPTED_LIST}" ]]; then
        print_info "No encrypted folders to decrypt"
        remove_lock
        return 0
    fi
    
    print_info "System startup detected - encrypted folders found"
    print_warning "Folders will remain encrypted until correct password is provided"
    
    # Verify password
    if ! verify_password; then
        echo
        print_error "Maximum attempts reached. Access denied."
        print_warning "Folders will remain encrypted."
        print_info "You can manually decrypt later using: folder_encryptor.sh decrypt <file>"
        echo
        log "SECURITY" "Failed login attempt - max attempts reached"
        
        # Keep lock to prevent immediate retry
        sleep 3
        return 1
    fi
    
    echo
    print_success "Password accepted! Starting decryption process..."
    log "SECURITY" "Successful authentication"
    
    # Decrypt all folders
    decrypt_all_folders "${MASTER_PASSWORD}"
    
    # Remove lock after successful decryption
    remove_lock
    
    print_success "All folders are now accessible!"
    echo
    read -p "Press Enter to continue to desktop..."
}

# ============================================================================
# SYSTEMD SERVICE MODE
# ============================================================================

service_mode() {
    # This mode is for systemd service execution
    # It will wait for user session and then prompt
    
    log "SERVICE" "Startup service initiated"
    
    # Wait for user session to be ready
    sleep 5
    
    # Check if X session or Wayland is available
    if [[ -z "${DISPLAY:-}" ]] && [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
        log "WARNING" "No display server detected, skipping GUI prompt"
        return 0
    fi
    
    # Run in terminal if available
    if command -v gnome-terminal &> /dev/null; then
        gnome-terminal -- bash -c "$(realpath "$0") --startup; exec bash"
    elif command -v xterm &> /dev/null; then
        xterm -e "$(realpath "$0") --startup; exec bash"
    elif command -v konsole &> /dev/null; then
        konsole -e "$(realpath "$0") --startup; exec bash"
    else
        # Fallback to console mode
        startup_routine
    fi
}

# ============================================================================
# INSTALLATION
# ============================================================================

install_service() {
    print_info "Installing startup decryption service..."
    
    local script_path="$(realpath "$0")"
    local service_file="/etc/systemd/system/folder-decrypt-startup.service"
    local user_service_dir="${HOME}/.config/systemd/user"
    local user_service_file="${user_service_dir}/folder-decrypt-startup.service"
    
    # Create user service directory
    mkdir -p "${user_service_dir}"
    
    # Create systemd user service
    cat > "${user_service_file}" << EOF
[Unit]
Description=Folder Decryption Startup Service
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=${script_path} --service
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF
    
    # Reload systemd and enable service
    systemctl --user daemon-reload
    systemctl --user enable folder-decrypt-startup.service
    
    print_success "Service installed successfully!"
    print_info "The decryption prompt will appear on next login"
    print_info "To test now, run: systemctl --user start folder-decrypt-startup.service"
    
    # Also add to bash profile as fallback
    local profile_file="${HOME}/.bash_profile"
    if [[ ! -f "${profile_file}" ]]; then
        profile_file="${HOME}/.profile"
    fi
    
    local profile_entry="# Folder Decryption Startup"
    if ! grep -q "${profile_entry}" "${profile_file}" 2>/dev/null; then
        cat >> "${profile_file}" << EOF

# Folder Decryption Startup
if [[ -f "${script_path}" ]]; then
    bash "${script_path}" --startup
fi
EOF
        print_success "Added to ${profile_file}"
    fi
}

uninstall_service() {
    print_info "Uninstalling startup decryption service..."
    
    local user_service_file="${HOME}/.config/systemd/user/folder-decrypt-startup.service"
    
    # Stop and disable service
    systemctl --user stop folder-decrypt-startup.service 2>/dev/null || true
    systemctl --user disable folder-decrypt-startup.service 2>/dev/null || true
    
    # Remove service file
    rm -f "${user_service_file}"
    
    # Reload systemd
    systemctl --user daemon-reload
    
    # Remove from profile
    local profile_file="${HOME}/.bash_profile"
    if [[ ! -f "${profile_file}" ]]; then
        profile_file="${HOME}/.profile"
    fi
    
    if [[ -f "${profile_file}" ]]; then
        sed -i '/# Folder Decryption Startup/,/^fi$/d' "${profile_file}"
    fi
    
    print_success "Service uninstalled successfully!"
}

# ============================================================================
# USAGE
# ============================================================================

show_usage() {
    cat << EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Automatic folder decryption at system startup

OPTIONS:
    --startup              Run startup routine (interactive)
    --service              Run as systemd service
    --install              Install as startup service
    --uninstall            Uninstall startup service
    --test                 Test decryption without lock
    -h, --help             Show this help message

EXAMPLES:
    ${SCRIPT_NAME} --install       Install the startup service
    ${SCRIPT_NAME} --startup       Run decryption prompt
    ${SCRIPT_NAME} --uninstall     Remove the startup service

EOF
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    # Ensure config directory exists
    mkdir -p "${CONFIG_DIR}"
    chmod 700 "${CONFIG_DIR}"
    
    # Parse arguments
    case "${1:-}" in
        --startup)
            startup_routine
            ;;
        --service)
            service_mode
            ;;
        --install)
            install_service
            ;;
        --uninstall)
            uninstall_service
            ;;
        --test)
            # Test mode without lock
            print_banner
            verify_password && decrypt_all_folders "${MASTER_PASSWORD}"
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            # Default: run startup routine
            startup_routine
            ;;
    esac
}

# Trap to clean up on exit
trap remove_lock EXIT

# Run main
main "$@"
