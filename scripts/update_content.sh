#!/bin/bash
# PrepperPi Enhanced Content Management Script
# Handles ZIM files, PDFs, maps, and other offline content sources

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="/opt/prepperpi/logs/content_update.log"
CONFIG_FILE="$BASE_DIR/config/kiwix.conf"
LOCK_FILE="/tmp/prepperpi_update.lock"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Load configuration
source "$CONFIG_FILE"

log() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error_log() {
    log "${RED}ERROR: $1${NC}"
}

success_log() {
    log "${GREEN}SUCCESS: $1${NC}"
}

info_log() {
    log "${BLUE}INFO: $1${NC}"
}

warning_log() {
    log "${YELLOW}WARNING: $1${NC}"
}

# Progress display function
show_progress() {
    local current=$1
    local total=$2
    local description=$3
    local percent=$((current * 100 / total))
    printf "\r${BLUE}[%3d%%]${NC} %s" "$percent" "$description"
}

# Check available disk space
check_disk_space() {
    local required_space_gb=$1
    local available_gb=$(df "$KIWIX_DATA_DIR" | awk 'NR==2 {printf "%.0f", $4/1024/1024}')
    
    if [[ $available_gb -lt $required_space_gb ]]; then
        error_log "Insufficient disk space. Required: ${required_space_gb}GB, Available: ${available_gb}GB"
        return 1
    fi
    
    info_log "Disk space check passed. Available: ${available_gb}GB"
    return 0
}

# Estimate download size for content sources
estimate_download_size() {
    local total_size=0
    
    # Rough size estimates in GB for different content types
    declare -A SIZE_ESTIMATES=(
        ["wikipedia_en_all_maxi"]="95"
        ["wikipedia_en_all_nopic"]="20"  
        ["wikipedia_en_top"]="15"
        ["wikivoyage"]="5"
        ["wiktionary"]="8"
        ["wikimed"]="3"
        ["gutenberg_all"]="70"
        ["gutenberg_selection"]="4"
        ["stackoverflow"]="50"
        ["khan-academy"]="25"
        ["wikihow"]="12"
        ["wikibooks"]="15"
        ["ted"]="8"
    )
    
    for source in "${CONTENT_SOURCES[@]}"; do
        for pattern in "${!SIZE_ESTIMATES[@]}"; do
            if [[ "$source" == *"$pattern"* ]]; then
                total_size=$((total_size + SIZE_ESTIMATES[$pattern]))
                break
            fi
        done
    done
    
    echo $total_size
}

# Verify ZIM file integrity
verify_zim_integrity() {
    local zim_file=$1
    
    if command -v kiwix-read >/dev/null 2>&1; then
        if kiwix-read "$zim_file" --list >/dev/null 2>&1; then
            success_log "ZIM file integrity verified: $(basename "$zim_file")"
            return 0
        else
            error_log "ZIM file integrity check failed: $(basename "$zim_file")"
            return 1
        fi
    else
        warning_log "kiwix-read not available, skipping integrity check"
        return 0
    fi
}

# Download ZIM files with progress and verification
download_zim_content() {
    info_log "Starting ZIM content download..."
    
    mkdir -p "$KIWIX_DATA_DIR"
    cd "$KIWIX_DATA_DIR"
    
    local total_sources=${#CONTENT_SOURCES[@]}
    local current_source=0
    
    for source in "${CONTENT_SOURCES[@]}"; do
        current_source=$((current_source + 1))
        filename=$(basename "$source")
        
        show_progress $current_source $total_sources "Downloading $filename"
        echo  # New line for wget output
        
        # Skip if file already exists and is valid
        if [[ -f "$filename" ]]; then
            if verify_zim_integrity "$filename"; then
                info_log "Skipping $filename (already exists and valid)"
                continue
            else
                warning_log "Re-downloading corrupted file: $filename"
                mv "$filename" "$filename.corrupted"
            fi
        fi
        
        # Download with resume support and progress
        local download_args=(
            -c                              # Continue partial downloads
            -t "$RETRY_ATTEMPTS"           # Retry attempts
            -T "$TIMEOUT_SECONDS"          # Timeout
            --progress=bar:force           # Force progress bar
            --show-progress               # Show progress
        )
        
        # Add bandwidth limiting if configured
        if [[ -n "${DOWNLOAD_LIMIT:-}" ]]; then
            download_args+=(--limit-rate="$DOWNLOAD_LIMIT")
        fi
        
        # Download to temporary file first
        if wget "${download_args[@]}" "$source" -O "$filename.tmp"; then
            # Verify downloaded file
            if verify_zim_integrity "$filename.tmp"; then
                mv "$filename.tmp" "$filename"
                success_log "Successfully downloaded and verified: $filename"
            else
                error_log "Downloaded file failed verification: $filename"
                mv "$filename.tmp" "$filename.failed"
                continue
            fi
        else
            error_log "Failed to download: $filename"
            rm -f "$filename.tmp"
            continue
        fi
    done
    
    echo  # New line after progress
    success_log "ZIM content download completed"
}

# Download PDF and document content
download_pdf_content() {
    info_log "Starting PDF and document download..."
    
    mkdir -p "$PDF_DATA_DIR" "$DOCUMENTS_DATA_DIR"
    
    # Download survival PDFs if configured
    if [[ ${#SURVIVAL_PDF_SOURCES[@]} -gt 0 ]]; then
        info_log "Downloading survival manuals..."
        cd "$PDF_DATA_DIR"
        
        for pdf_source in "${SURVIVAL_PDF_SOURCES[@]}"; do
            filename=$(basename "$pdf_source")
            
            if [[ -f "$filename" ]]; then
                info_log "Skipping $filename (already exists)"
                continue
            fi
            
            info_log "Downloading: $filename"
            if wget -c -t 3 -T 300 "$pdf_source" -O "$filename.tmp"; then
                mv "$filename.tmp" "$filename"
                success_log "Downloaded: $filename"
            else
                error_log "Failed to download: $filename"
                rm -f "$filename.tmp"
            fi
        done
    fi
    
    # Download medical PDFs if configured  
    if [[ ${#MEDICAL_PDF_SOURCES[@]} -gt 0 ]]; then
        info_log "Downloading medical resources..."
        
        for medical_source in "${MEDICAL_PDF_SOURCES[@]}"; do
            filename=$(basename "$medical_source")
            
            if [[ -f "$filename" ]]; then
                info_log "Skipping $filename (already exists)"
                continue
            fi
            
            info_log "Downloading: $filename"
            if wget -c -t 3 -T 300 "$medical_source" -O "$filename.tmp"; then
                mv "$filename.tmp" "$filename"
                success_log "Downloaded: $filename"
            else
                warning_log "Failed to download: $filename (may require manual download)"
                rm -f "$filename.tmp"
            fi
        done
    fi
    
    success_log "PDF and document download completed"
}

# Setup offline maps (OpenStreetMap data)
setup_offline_maps() {
    info_log "Setting up offline maps..."
    
    local maps_dir="/opt/prepperpi/data/maps"
    mkdir -p "$maps_dir"
    
    # Create maps configuration
    cat > "$maps_dir/maps_info.txt" << EOF
PrepperPi Offline Maps Setup

For comprehensive offline maps, you have several options:

1. OSMAnd Maps:
   - Download OSMAnd Android APK from F-Droid or official site
   - Download regional .obf map files from: https://download.osmand.net/
   - Recommended regions: North America, Europe, etc.

2. Maps.me:
   - Download Maps.me APK
   - Maps automatically download when accessed

3. Web-based maps (for Pi display):
   - Use TileServer GL with OSM data
   - Download regional extracts from: https://download.geofabrik.de/

4. Manual map tiles:
   - Use tools like TileMill or Mapnik to generate tiles
   - Store in MBTiles format for offline use

Current PrepperPi doesn't include maps due to size constraints.
Consider dedicating separate storage for comprehensive mapping.
EOF
    
    info_log "Maps setup information created at $maps_dir/maps_info.txt"
}

# Update Kiwix library with all ZIM files
update_kiwix_library() {
    info_log "Updating Kiwix library..."
    
    cd "$KIWIX_DATA_DIR"
    
    # Initialize library if it doesn't exist
    if [[ ! -f "$KIWIX_LIBRARY_FILE" ]]; then
        touch "$KIWIX_LIBRARY_FILE"
        info_log "Created new Kiwix library file"
    fi
    
    # Add all ZIM files to library
    local zim_count=0
    for zim_file in *.zim; do
        if [[ -f "$zim_file" ]]; then
            if kiwix-manage "$KIWIX_LIBRARY_FILE" add "$zim_file" 2>/dev/null; then
                success_log "Added to library: $zim_file"
                zim_count=$((zim_count + 1))
            else
                warning_log "Failed to add to library: $zim_file"
            fi
        fi
    done
    
    info_log "Added $zim_count ZIM files to library"
    
    # Restart Kiwix service to reload library
    if systemctl is-active --quiet prepperpi-kiwix; then
        info_log "Restarting Kiwix service..."
        systemctl restart prepperpi-kiwix || warning_log "Failed to restart Kiwix service"
    fi
    
    success_log "Kiwix library update completed"
}

# Cleanup old and corrupted files
cleanup_content() {
    info_log "Cleaning up old and corrupted files..."
    
    cd "$KIWIX_DATA_DIR"
    
    # Remove temporary files
    find . -name "*.tmp" -delete 2>/dev/null || true
    find . -name "*.failed" -delete 2>/dev/null || true
    find . -name "*.corrupted" -delete 2>/dev/null || true
    
    # Remove old versions if space is low
    if [[ "${AUTO_CLEANUP:-false}" == "true" ]]; then
        local available_gb=$(df "$KIWIX_DATA_DIR" | awk 'NR==2 {printf "%.0f", $4/1024/1024}')
        local min_space_gb=$(echo "${MIN_FREE_SPACE:-5GB}" | sed 's/GB//')
        
        if [[ $available_gb -lt $min_space_gb ]]; then
            warning_log "Low disk space, removing old content versions..."
            
            # Remove older duplicate ZIM files (keep newest)
            for base_name in wikipedia wikivoyage wiktionary gutenberg; do
                ls -t ${base_name}*zim 2>/dev/null | tail -n +2 | xargs rm -f || true
            done
        fi
    fi
    
    success_log "Cleanup completed"
}

# Generate content report
generate_content_report() {
    info_log "Generating content report..."
    
    local report_file="/opt/prepperpi/logs/content_report.txt"
    
    cat > "$report_file" << EOF
PrepperPi Content Report
Generated: $(date)
=================================

ZIM Files (Kiwix Content):
$(find "$KIWIX_DATA_DIR" -name "*.zim" -exec ls -lh {} \; 2>/dev/null | awk '{print $9, $5}' || echo "None found")

PDF Documents:
$(find "$PDF_DATA_DIR" -name "*.pdf" -exec ls -lh {} \; 2>/dev/null | awk '{print $9, $5}' || echo "None found")

Storage Usage:
$(df -h "$KIWIX_DATA_DIR" 2>/dev/null || echo "Unable to determine")

Kiwix Library Status:
$(kiwix-manage "$KIWIX_LIBRARY_FILE" show 2>/dev/null | wc -l || echo "0") content items registered

Last Updated: $(date)
EOF
    
    info_log "Content report saved to $report_file"
}

# Check prerequisites and system requirements  
check_prerequisites() {
    info_log "Checking prerequisites..."
    
    # Check required commands
    local required_commands=("wget" "kiwix-manage" "kiwix-serve")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            error_log "Required command not found: $cmd"
            error_log "Please run the installation script first"
            exit 1
        fi
    done
    
    # Check internet connectivity
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        error_log "No internet connection available"
        error_log "Internet connection required for downloading content"
        exit 1
    fi
    
    # Estimate required space
    local estimated_size=$(estimate_download_size)
    info_log "Estimated download size: ${estimated_size}GB"
    
    # Check available space (add 20% buffer)
    local required_space=$((estimated_size + estimated_size / 5))
    if ! check_disk_space "$required_space"; then
        error_log "Insufficient disk space for selected content"
        error_log "Consider changing STORAGE_PROFILE in config or adding storage"
        exit 1
    fi
    
    success_log "Prerequisites check passed"
}

# Main content update function
main_update() {
    info_log "Starting PrepperPi comprehensive content update..."
    
    # Check if update is already running
    if [[ -f "$LOCK_FILE" ]]; then
        error_log "Content update already in progress (lock file exists)"
        error_log "If this is incorrect, remove $LOCK_FILE and try again"
        exit 1
    fi
    
    # Create lock file
    echo $$ > "$LOCK_FILE"
    
    # Cleanup function
    cleanup() {
        rm -f "$LOCK_FILE"
        info_log "Content update process finished"
    }
    trap cleanup EXIT
    
    # Run update process
    check_prerequisites
    download_zim_content
    download_pdf_content  
    setup_offline_maps
    update_kiwix_library
    cleanup_content
    generate_content_report
    
    success_log "PrepperPi content update completed successfully!"
    info_log "Access your offline content at: http://prepperpi.local/kiwix/"
    
    # Display content summary
    echo
    echo "Content Summary:"
    echo "================"
    echo "ZIM Files: $(find "$KIWIX_DATA_DIR" -name "*.zim" | wc -l)"
    echo "PDF Documents: $(find "$PDF_DATA_DIR" -name "*.pdf" | wc -l 2>/dev/null || echo 0)"
    echo "Total Storage Used: $(du -sh "$KIWIX_DATA_DIR" 2>/dev/null | cut -f1 || echo "Unknown")"
}

# Command line options
case "${1:-update}" in
    "update")
        main_update
        ;;
    "verify")
        info_log "Verifying existing content..."
        cd "$KIWIX_DATA_DIR"
        for zim_file in *.zim; do
            if [[ -f "$zim_file" ]]; then
                verify_zim_integrity "$zim_file"
            fi
        done
        ;;
    "cleanup")
        cleanup_content
        ;;
    "report")
        generate_content_report
        cat "/opt/prepperpi/logs/content_report.txt"
        ;;
    "estimate")
        estimated_size=$(estimate_download_size)
        echo "Estimated download size for current configuration: ${estimated_size}GB"
        ;;
    "help"|"-h"|"--help")
        echo "PrepperPi Content Manager"
        echo
        echo "Usage: $0 [command]"
        echo
        echo "Commands:"
        echo "  update    - Download and update all content (default)"
        echo "  verify    - Verify integrity of existing content"  
        echo "  cleanup   - Clean up temporary and old files"
        echo "  report    - Generate content usage report"
        echo "  estimate  - Estimate download size for current config"
        echo "  help      - Show this help message"
        echo
        echo "Configuration is read from: $CONFIG_FILE"
        ;;
    *)
        error_log "Unknown command: $1"
        echo "Use '$0 help' for available commands"
        exit 1
        ;;
esac