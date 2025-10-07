#!/bin/bash

################################################################################
# TEST SUITE - Folder Encryption System Testing
# Version: 1.0.0
# Description: Comprehensive test suite for the encryption system
# Author: Anmysec
# License: MIT
################################################################################

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Test configuration
readonly TEST_DIR="/tmp/folder_encryption_test_$$"
readonly TEST_PASSWORD="TestP@ssw0rd123"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

print_header() {
    echo
    echo "═══════════════════════════════════════════════════════════════"
    echo "  $*"
    echo "═══════════════════════════════════════════════════════════════"
    echo
}

print_test() {
    echo -ne "${BLUE}[TEST]${NC} $*... "
}

print_pass() {
    echo -e "${GREEN}✓ PASS${NC}"
    ((TESTS_PASSED++))
}

print_fail() {
    echo -e "${RED}✗ FAIL${NC}"
    if [[ $# -gt 0 ]]; then
        echo -e "${RED}       $*${NC}"
    fi
    ((TESTS_FAILED++))
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

# ============================================================================
# SETUP AND CLEANUP
# ============================================================================

setup_test_env() {
    print_info "Setting up test environment..."
    
    # Create test directory
    mkdir -p "${TEST_DIR}"
    
    # Create test folders with content
    mkdir -p "${TEST_DIR}/test_folder_1"
    echo "Test file 1" > "${TEST_DIR}/test_folder_1/file1.txt"
    echo "Test file 2" > "${TEST_DIR}/test_folder_1/file2.txt"
    mkdir -p "${TEST_DIR}/test_folder_1/subfolder"
    echo "Nested file" > "${TEST_DIR}/test_folder_1/subfolder/nested.txt"
    
    mkdir -p "${TEST_DIR}/test_folder_2"
    echo "Another test" > "${TEST_DIR}/test_folder_2/data.txt"
    
    mkdir -p "${TEST_DIR}/empty_folder"
    
    print_info "Test environment created at: ${TEST_DIR}"
}

cleanup_test_env() {
    print_info "Cleaning up test environment..."
    rm -rf "${TEST_DIR}"
    print_info "Test environment cleaned"
}

# ============================================================================
# TEST FUNCTIONS
# ============================================================================

test_dependencies() {
    print_test "Checking dependencies"
    ((TESTS_RUN++))
    
    local missing=()
    for cmd in openssl tar bash; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -eq 0 ]]; then
        print_pass
    else
        print_fail "Missing: ${missing[*]}"
    fi
}

test_script_exists() {
    print_test "Checking if encryption script exists"
    ((TESTS_RUN++))
    
    if [[ -f "${SCRIPT_DIR}/folder_encryptor.sh" ]]; then
        print_pass
    else
        print_fail "folder_encryptor.sh not found"
    fi
}

test_script_executable() {
    print_test "Checking if script is executable"
    ((TESTS_RUN++))
    
    if [[ -x "${SCRIPT_DIR}/folder_encryptor.sh" ]]; then
        print_pass
    else
        chmod +x "${SCRIPT_DIR}/folder_encryptor.sh"
        if [[ -x "${SCRIPT_DIR}/folder_encryptor.sh" ]]; then
            print_pass
        else
            print_fail "Cannot make script executable"
        fi
    fi
}

test_encrypt_folder() {
    print_test "Encrypting test folder"
    ((TESTS_RUN++))
    
    local test_folder="${TEST_DIR}/test_folder_1"
    local encrypted_file="${test_folder}.klskv"
    
    if echo -e "${TEST_PASSWORD}\n${TEST_PASSWORD}" | \
       bash "${SCRIPT_DIR}/folder_encryptor.sh" encrypt "${test_folder}" &> /dev/null; then
        if [[ -f "${encrypted_file}" ]]; then
            print_pass
        else
            print_fail "Encrypted file not created"
        fi
    else
        print_fail "Encryption command failed"
    fi
}

test_encrypted_file_format() {
    print_test "Verifying encrypted file format"
    ((TESTS_RUN++))
    
    local encrypted_file="${TEST_DIR}/test_folder_1.klskv"
    
    if [[ -f "${encrypted_file}" ]]; then
        # Check if file is binary (encrypted)
        if file "${encrypted_file}" | grep -q "data"; then
            print_pass
        else
            print_fail "File doesn't appear to be encrypted"
        fi
    else
        print_fail "Encrypted file not found"
    fi
}

test_decrypt_folder() {
    print_test "Decrypting test folder"
    ((TESTS_RUN++))
    
    local encrypted_file="${TEST_DIR}/test_folder_1.klskv"
    local decrypted_folder="${TEST_DIR}/test_folder_1"
    
    # Remove original if exists
    rm -rf "${decrypted_folder}"
    
    if echo -e "${TEST_PASSWORD}\nn" | \
       bash "${SCRIPT_DIR}/folder_encryptor.sh" decrypt "${encrypted_file}" &> /dev/null; then
        if [[ -d "${decrypted_folder}" ]]; then
            print_pass
        else
            print_fail "Decrypted folder not created"
        fi
    else
        print_fail "Decryption command failed"
    fi
}

test_decrypted_content() {
    print_test "Verifying decrypted content integrity"
    ((TESTS_RUN++))
    
    local decrypted_folder="${TEST_DIR}/test_folder_1"
    local errors=()
    
    if [[ ! -f "${decrypted_folder}/file1.txt" ]]; then
        errors+=("file1.txt missing")
    elif [[ "$(cat "${decrypted_folder}/file1.txt")" != "Test file 1" ]]; then
        errors+=("file1.txt content mismatch")
    fi
    
    if [[ ! -f "${decrypted_folder}/file2.txt" ]]; then
        errors+=("file2.txt missing")
    fi
    
    if [[ ! -f "${decrypted_folder}/subfolder/nested.txt" ]]; then
        errors+=("nested file missing")
    fi
    
    if [[ ${#errors[@]} -eq 0 ]]; then
        print_pass
    else
        print_fail "${errors[*]}"
    fi
}

test_wrong_password() {
    print_test "Testing wrong password rejection"
    ((TESTS_RUN++))
    
    local encrypted_file="${TEST_DIR}/test_folder_1.klskv"
    local wrong_password="WrongPassword123"
    
    # Try to decrypt with wrong password
    if echo "${wrong_password}" | \
       bash "${SCRIPT_DIR}/folder_encryptor.sh" decrypt "${encrypted_file}" &> /dev/null; then
        print_fail "Accepted wrong password"
    else
        print_pass
    fi
}

test_empty_folder() {
    print_test "Encrypting empty folder"
    ((TESTS_RUN++))
    
    local empty_folder="${TEST_DIR}/empty_folder"
    local encrypted_file="${empty_folder}.klskv"
    
    if echo -e "${TEST_PASSWORD}\n${TEST_PASSWORD}" | \
       bash "${SCRIPT_DIR}/folder_encryptor.sh" encrypt "${empty_folder}" &> /dev/null; then
        if [[ -f "${encrypted_file}" ]]; then
            print_pass
        else
            print_fail "Failed to encrypt empty folder"
        fi
    else
        print_fail "Encryption command failed"
    fi
}

test_list_command() {
    print_test "Testing list command"
    ((TESTS_RUN++))
    
    if bash "${SCRIPT_DIR}/folder_encryptor.sh" list &> /dev/null; then
        print_pass
    else
        print_fail "List command failed"
    fi
}

test_help_command() {
    print_test "Testing help command"
    ((TESTS_RUN++))
    
    if bash "${SCRIPT_DIR}/folder_encryptor.sh" --help &> /dev/null; then
        print_pass
    else
        print_fail "Help command failed"
    fi
}

test_version_command() {
    print_test "Testing version command"
    ((TESTS_RUN++))
    
    if bash "${SCRIPT_DIR}/folder_encryptor.sh" --version &> /dev/null; then
        print_pass
    else
        print_fail "Version command failed"
    fi
}

test_startup_script_exists() {
    print_test "Checking if startup script exists"
    ((TESTS_RUN++))
    
    if [[ -f "${SCRIPT_DIR}/auto_decrypt_startup.sh" ]]; then
        print_pass
    else
        print_fail "auto_decrypt_startup.sh not found"
    fi
}

test_install_script_exists() {
    print_test "Checking if install script exists"
    ((TESTS_RUN++))
    
    if [[ -f "${SCRIPT_DIR}/install.sh" ]]; then
        print_pass
    else
        print_fail "install.sh not found"
    fi
}

test_config_directory() {
    print_test "Testing config directory creation"
    ((TESTS_RUN++))
    
    local config_dir="${HOME}/.folder_encryptor"
    
    if [[ -d "${config_dir}" ]]; then
        print_pass
    else
        print_fail "Config directory not created"
    fi
}

test_log_files() {
    print_test "Testing log file creation"
    ((TESTS_RUN++))
    
    local log_file="${HOME}/.folder_encryptor/encryption.log"
    
    if [[ -f "${log_file}" ]]; then
        print_pass
    else
        print_fail "Log file not created"
    fi
}

# ============================================================================
# PERFORMANCE TESTS
# ============================================================================

test_large_folder_performance() {
    print_test "Testing large folder encryption performance"
    ((TESTS_RUN++))
    
    local large_folder="${TEST_DIR}/large_folder"
    mkdir -p "${large_folder}"
    
    # Create 100 files
    for i in {1..100}; do
        dd if=/dev/urandom of="${large_folder}/file_${i}.dat" bs=1K count=100 2>/dev/null
    done
    
    local start_time=$(date +%s)
    
    if echo -e "${TEST_PASSWORD}\n${TEST_PASSWORD}\nn" | \
       bash "${SCRIPT_DIR}/folder_encryptor.sh" encrypt "${large_folder}" &> /dev/null; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        if [[ -f "${large_folder}.klskv" ]]; then
            print_pass
            print_info "Encryption took ${duration} seconds"
        else
            print_fail "Encrypted file not created"
        fi
    else
        print_fail "Encryption failed"
    fi
}

# ============================================================================
# SECURITY TESTS
# ============================================================================

test_file_permissions() {
    print_test "Testing encrypted file permissions"
    ((TESTS_RUN++))
    
    local encrypted_file="${TEST_DIR}/test_folder_1.klskv"
    
    if [[ -f "${encrypted_file}" ]]; then
        local perms=$(stat -c %a "${encrypted_file}" 2>/dev/null || stat -f %A "${encrypted_file}" 2>/dev/null)
        
        if [[ "${perms}" == "600" ]]; then
            print_pass
        else
            print_warning "Permissions are ${perms}, expected 600"
            print_pass
        fi
    else
        print_fail "Encrypted file not found"
    fi
}

test_config_permissions() {
    print_test "Testing config directory permissions"
    ((TESTS_RUN++))
    
    local config_dir="${HOME}/.folder_encryptor"
    
    if [[ -d "${config_dir}" ]]; then
        local perms=$(stat -c %a "${config_dir}" 2>/dev/null || stat -f %A "${config_dir}" 2>/dev/null)
        
        if [[ "${perms}" == "700" ]]; then
            print_pass
        else
            print_warning "Permissions are ${perms}, expected 700"
            print_pass
        fi
    else
        print_fail "Config directory not found"
    fi
}

# ============================================================================
# MAIN TEST RUNNER
# ============================================================================

run_all_tests() {
    print_header "FOLDER ENCRYPTION SYSTEM - TEST SUITE"
    
    print_info "Starting comprehensive test suite..."
    print_info "Test directory: ${TEST_DIR}"
    echo
    
    # Setup
    setup_test_env
    
    # Basic tests
    print_header "BASIC TESTS"
    test_dependencies
    test_script_exists
    test_script_executable
    test_startup_script_exists
    test_install_script_exists
    
    # Functionality tests
    print_header "FUNCTIONALITY TESTS"
    test_encrypt_folder
    test_encrypted_file_format
    test_decrypt_folder
    test_decrypted_content
    test_wrong_password
    test_empty_folder
    
    # Command tests
    print_header "COMMAND TESTS"
    test_list_command
    test_help_command
    test_version_command
    
    # Configuration tests
    print_header "CONFIGURATION TESTS"
    test_config_directory
    test_log_files
    
    # Security tests
    print_header "SECURITY TESTS"
    test_file_permissions
    test_config_permissions
    
    # Performance tests
    print_header "PERFORMANCE TESTS"
    test_large_folder_performance
    
    # Cleanup
    cleanup_test_env
    
    # Results
    print_header "TEST RESULTS"
    echo
    echo "Total Tests:  ${TESTS_RUN}"
    echo -e "${GREEN}Passed:       ${TESTS_PASSED}${NC}"
    echo -e "${RED}Failed:       ${TESTS_FAILED}${NC}"
    echo
    
    local success_rate=$((TESTS_PASSED * 100 / TESTS_RUN))
    echo "Success Rate: ${success_rate}%"
    echo
    
    if [[ ${TESTS_FAILED} -eq 0 ]]; then
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                                                               ║${NC}"
        echo -e "${GREEN}║                  ✓ ALL TESTS PASSED! ✓                        ║${NC}"
        echo -e "${GREEN}║                                                               ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        return 0
    else
        echo -e "${RED}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║                                                               ║${NC}"
        echo -e "${RED}║                  ✗ SOME TESTS FAILED ✗                        ║${NC}"
        echo -e "${RED}║                                                               ║${NC}"
        echo -e "${RED}╚═══════════════════════════════════════════════════════════════╝${NC}"
        return 1
    fi
}

# ============================================================================
# ENTRY POINT
# ============================================================================

main() {
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        echo -e "${RED}[ERROR]${NC} Do not run tests as root"
        exit 1
    fi
    
    # Run tests
    run_all_tests
    exit $?
}

# Run main
main "$@"
