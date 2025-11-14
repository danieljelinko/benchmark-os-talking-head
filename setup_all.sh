#!/bin/bash
set -euo pipefail

# ==========================================
# Automated Complete Setup Script
# ==========================================
# This script automates the complete installation process:
# 1. Bootstrap system dependencies (git, ffmpeg, UV)
# 2. Install TTS backends (Coqui and Piper)
# 3. Install all talking-head solutions
#
# Usage: bash setup_all.sh [options]
#
# Options:
#   --skip-bootstrap    Skip system dependencies installation
#   --skip-tts          Skip TTS backend installation
#   --skip-solutions    Skip solution installation
#   --solutions <list>  Install specific solutions only (comma-separated)
#                       Example: --solutions sadtalker,wav2lip
#
# Examples:
#   bash setup_all.sh                              # Install everything
#   bash setup_all.sh --skip-bootstrap             # Skip system setup
#   bash setup_all.sh --solutions sadtalker        # Install only SadTalker

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration flags
SKIP_BOOTSTRAP=false
SKIP_TTS=false
SKIP_SOLUTIONS=false
SPECIFIC_SOLUTIONS=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-bootstrap)
            SKIP_BOOTSTRAP=true
            shift
            ;;
        --skip-tts)
            SKIP_TTS=true
            shift
            ;;
        --skip-solutions)
            SKIP_SOLUTIONS=true
            shift
            ;;
        --solutions)
            SPECIFIC_SOLUTIONS="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --skip-bootstrap    Skip system dependencies installation"
            echo "  --skip-tts          Skip TTS backend installation"
            echo "  --skip-solutions    Skip solution installation"
            echo "  --solutions <list>  Install specific solutions (comma-separated)"
            echo ""
            echo "Examples:"
            echo "  $0                                   # Install everything"
            echo "  $0 --skip-bootstrap                  # Skip system setup"
            echo "  $0 --solutions sadtalker,wav2lip     # Install specific solutions"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Run with --help for usage information"
            exit 1
            ;;
    esac
done

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Log file
LOG_FILE="$SCRIPT_DIR/setup_all.log"
echo "Setup started at $(date)" > "$LOG_FILE"

# Helper function for logging
log() {
    echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[$(date +%H:%M:%S)] ✓${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date +%H:%M:%S)] ✗${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[$(date +%H:%M:%S)] ⚠${NC} $1" | tee -a "$LOG_FILE"
}

echo ""
echo "================================================"
echo "  Benchmark Talking Head Solutions - Setup"
echo "================================================"
echo ""
echo "This script will install:"
if [ "$SKIP_BOOTSTRAP" = false ]; then
    echo "  ✓ System dependencies (git, ffmpeg, UV)"
else
    echo "  ✗ System dependencies (SKIPPED)"
fi

if [ "$SKIP_TTS" = false ]; then
    echo "  ✓ TTS backends (Coqui, Piper)"
else
    echo "  ✗ TTS backends (SKIPPED)"
fi

if [ "$SKIP_SOLUTIONS" = false ]; then
    if [ -n "$SPECIFIC_SOLUTIONS" ]; then
        echo "  ✓ Solutions: $SPECIFIC_SOLUTIONS"
    else
        echo "  ✓ All solutions (SadTalker, Wav2Lip, EchoMimic, V-Express, Audio2Head)"
    fi
else
    echo "  ✗ Solutions (SKIPPED)"
fi

echo ""
echo "Installation log: $LOG_FILE"
echo ""
read -p "Continue with installation? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log "Installation cancelled by user"
    exit 0
fi

# Track failures
FAILED_STEPS=()

# ==========================================
# Step 1: Bootstrap System
# ==========================================
if [ "$SKIP_BOOTSTRAP" = false ]; then
    echo ""
    echo "================================================"
    echo "Step 1: Installing System Dependencies"
    echo "================================================"
    echo ""

    log "Running bootstrap/install_system_deps.sh..."
    if bash bootstrap/install_system_deps.sh >> "$LOG_FILE" 2>&1; then
        log_success "System dependencies installed"
    else
        log_error "Failed to install system dependencies"
        FAILED_STEPS+=("bootstrap")
    fi

    # Check UV is available for current shell
    if command -v uv &> /dev/null; then
        log_success "UV is available in current session"
    else
        log_warning "UV not in PATH. You may need to: export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
else
    log_warning "Skipping bootstrap (--skip-bootstrap)"
fi

# ==========================================
# Step 2: Install TTS Backends
# ==========================================
if [ "$SKIP_TTS" = false ]; then
    echo ""
    echo "================================================"
    echo "Step 2: Installing TTS Backends"
    echo "================================================"
    echo ""

    # Coqui TTS
    log "Installing Coqui TTS..."
    if bash tts/setup_coqui.sh >> "$LOG_FILE" 2>&1; then
        log_success "Coqui TTS installed"
    else
        log_error "Failed to install Coqui TTS"
        FAILED_STEPS+=("coqui-tts")
    fi

    # Piper TTS
    log "Installing Piper TTS..."
    if bash tts/setup_piper.sh >> "$LOG_FILE" 2>&1; then
        log_success "Piper TTS installed"
    else
        log_error "Failed to install Piper TTS"
        FAILED_STEPS+=("piper-tts")
    fi
else
    log_warning "Skipping TTS backends (--skip-tts)"
fi

# ==========================================
# Step 3: Install Solutions
# ==========================================
if [ "$SKIP_SOLUTIONS" = false ]; then
    echo ""
    echo "================================================"
    echo "Step 3: Installing Talking Head Solutions"
    echo "================================================"
    echo ""

    # Determine which solutions to install
    if [ -n "$SPECIFIC_SOLUTIONS" ]; then
        # Convert comma-separated list to array
        IFS=',' read -ra SOLUTIONS <<< "$SPECIFIC_SOLUTIONS"
    else
        # Install all solutions
        SOLUTIONS=(sadtalker wav2lip echomimic v_express audio2head)
    fi

    # Install each solution
    for solution in "${SOLUTIONS[@]}"; do
        solution=$(echo "$solution" | xargs) # Trim whitespace

        case "$solution" in
            sadtalker)
                log "Installing SadTalker..."
                if bash solutions/sadtalker/setup.sh >> "$LOG_FILE" 2>&1; then
                    log_success "SadTalker installed"
                else
                    log_error "Failed to install SadTalker"
                    FAILED_STEPS+=("sadtalker")
                fi
                ;;
            wav2lip)
                log "Installing Wav2Lip..."
                if bash solutions/wav2lip/setup.sh >> "$LOG_FILE" 2>&1; then
                    log_success "Wav2Lip installed"
                else
                    log_error "Failed to install Wav2Lip"
                    FAILED_STEPS+=("wav2lip")
                fi
                ;;
            echomimic)
                log "Installing EchoMimic..."
                if bash solutions/echomimic/setup.sh >> "$LOG_FILE" 2>&1; then
                    log_success "EchoMimic installed"
                else
                    log_error "Failed to install EchoMimic"
                    FAILED_STEPS+=("echomimic")
                fi
                ;;
            v_express)
                log "Installing V-Express..."
                if bash solutions/v_express/setup.sh >> "$LOG_FILE" 2>&1; then
                    log_success "V-Express installed"
                else
                    log_error "Failed to install V-Express"
                    FAILED_STEPS+=("v_express")
                fi
                ;;
            audio2head)
                log "Installing Audio2Head..."
                if bash solutions/audio2head/setup.sh >> "$LOG_FILE" 2>&1; then
                    log_success "Audio2Head installed"
                else
                    log_error "Failed to install Audio2Head"
                    FAILED_STEPS+=("audio2head")
                fi
                ;;
            *)
                log_error "Unknown solution: $solution"
                FAILED_STEPS+=("$solution (unknown)")
                ;;
        esac
    done
else
    log_warning "Skipping solutions (--skip-solutions)"
fi

# ==========================================
# Final Summary
# ==========================================
echo ""
echo "================================================"
echo "  Setup Complete!"
echo "================================================"
echo ""

if [ ${#FAILED_STEPS[@]} -eq 0 ]; then
    log_success "All components installed successfully!"
    echo ""
    echo "Next steps:"
    echo "  1. Restart your shell or run: source ~/.bashrc"
    echo "  2. Run inference:"
    echo "     ./run.sh sadtalker --image assets/test.jpg --text \"Hello world\""
    echo ""
else
    log_warning "Setup completed with ${#FAILED_STEPS[@]} failure(s):"
    for step in "${FAILED_STEPS[@]}"; do
        echo "  - $step"
    done
    echo ""
    echo "Check the log file for details: $LOG_FILE"
    echo ""
    echo "You can retry failed components individually:"
    echo "  bash bootstrap/install_system_deps.sh"
    echo "  bash tts/setup_coqui.sh"
    echo "  bash solutions/sadtalker/setup.sh"
    echo "  etc."
    echo ""
fi

echo "Full installation log: $LOG_FILE"
echo ""
echo "================================================"
echo ""
