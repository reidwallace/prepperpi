#!/bin/bash
# PrepperPi Content Update Script

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$BASE_DIR/logs/content_update.log"
CONFIG_FILE="$BASE_DIR/config/kiwix.conf"
LOCK_FILE="/tmp/prepperpi_update.lock"

source "$CONFIG_FILE"

log()         { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }
error_log()   { log "ERROR: $1"; }
success_log() { log "SUCCESS: $1"; }
info_log()    { log "INFO: $1"; }
warning_log() { log "WARNING: $1"; }

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

estimate_download_size() {
    local total_size=0

    declare -A SIZE_ESTIMATES=(
        ["wikipedia_en_all_maxi"]="111"
        ["wikipedia_en_all_nopic"]="48"
        ["wikipedia_en_top"]="8"
        ["wikivoyage"]="2"
        ["wiktionary"]="8"
        ["wikibooks"]="6"
        ["wikiversity"]="3"
        ["wikinews"]="1"
        ["gutenberg"]="206"
        ["stackoverflow"]="75"
        ["askubuntu"]="3"
        ["superuser"]="4"
        ["ted"]="79"
        ["based.cooking"]="1"
        ["cheatography"]="11"
        ["armypubs"]="8"
        ["anonymousplanet"]="1"
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

verify_zim_integrity() {
    local zim_file=$1

    if command -v kiwix-read >/dev/null 2>&1; then
        if kiwix-read "$zim_file" --list >/dev/null 2>&1; then
            success_log "Verified: $(basename "$zim_file")"
            return 0
        else
            error_log "Integrity check failed: $(basename "$zim_file")"
            return 1
        fi
    else
        # No kiwix-read, just check file size is nonzero
        if [[ -s "$zim_file" ]]; then
            return 0
        else
            return 1
        fi
    fi
}

download_zim_content() {
    info_log "Starting ZIM content download..."

    mkdir -p "$KIWIX_DATA_DIR"
    cd "$KIWIX_DATA_DIR"

    local total_sources=${#CONTENT_SOURCES[@]}
    local current_source=0

    for source in "${CONTENT_SOURCES[@]}"; do
        current_source=$((current_source + 1))
        filename=$(basename "$source")

        info_log "[$current_source/$total_sources] $filename"

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

        local wget_args=(
            -c
            -t "$RETRY_ATTEMPTS"
            -T "$TIMEOUT_SECONDS"
        )

        if [[ -n "${DOWNLOAD_LIMIT:-}" ]]; then
            wget_args+=(--limit-rate="$DOWNLOAD_LIMIT")
        fi

        if wget "${wget_args[@]}" "$source" -O "$filename.tmp"; then
            if verify_zim_integrity "$filename.tmp"; then
                mv "$filename.tmp" "$filename"
                success_log "Downloaded: $filename"
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

    success_log "ZIM content download completed"
}

download_pdf_content() {
    info_log "Starting PDF and document download..."

    mkdir -p "$PDF_DATA_DIR" "$DOCUMENTS_DATA_DIR"

    if [[ ${#SURVIVAL_PDF_SOURCES[@]} -gt 0 ]]; then
        cd "$PDF_DATA_DIR"
        for pdf_source in "${SURVIVAL_PDF_SOURCES[@]}"; do
            filename=$(basename "$pdf_source")
            [[ -f "$filename" ]] && continue
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

    if [[ ${#MEDICAL_PDF_SOURCES[@]} -gt 0 ]]; then
        for medical_source in "${MEDICAL_PDF_SOURCES[@]}"; do
            filename=$(basename "$medical_source")
            [[ -f "$filename" ]] && continue
            if wget -c -t 3 -T 300 "$medical_source" -O "$filename.tmp"; then
                mv "$filename.tmp" "$filename"
            else
                rm -f "$filename.tmp"
            fi
        done
    fi

    success_log "PDF and document download completed"
}

update_kiwix_library() {
    info_log "Updating Kiwix library..."

    cd "$KIWIX_DATA_DIR"
    rm -f "$KIWIX_LIBRARY_FILE"

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

    if systemctl is-active --quiet prepperpi-kiwix; then
        info_log "Restarting Kiwix service..."
        systemctl restart prepperpi-kiwix || warning_log "Failed to restart Kiwix service"
    fi

    success_log "Kiwix library update completed"
}

cleanup_content() {
    info_log "Cleaning up temp files..."
    cd "$KIWIX_DATA_DIR"
    find . -name "*.tmp" -delete 2>/dev/null || true
    find . -name "*.failed" -delete 2>/dev/null || true
    find . -name "*.corrupted" -delete 2>/dev/null || true
    success_log "Cleanup completed"
}

generate_content_report() {
    local report_file="$BASE_DIR/logs/content_report.txt"
    cat > "$report_file" << EOF
PrepperPi Content Report - $(date)
=================================
ZIM Files:
$(ls -lh "$KIWIX_DATA_DIR"/*.zim 2>/dev/null || echo "None found")

Storage Usage:
$(df -h "$KIWIX_DATA_DIR" 2>/dev/null || echo "Unable to determine")
EOF
    info_log "Content report saved to $report_file"
}

check_prerequisites() {
    info_log "Checking prerequisites..."

    for cmd in wget kiwix-manage kiwix-serve; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            error_log "Required command not found: $cmd"
            exit 1
        fi
    done

    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        error_log "No internet connection"
        exit 1
    fi

    local estimated_size=$(estimate_download_size)
    info_log "Estimated download size: ${estimated_size}GB"

    local required_space=$((estimated_size + estimated_size / 5))
    if ! check_disk_space "$required_space"; then
        error_log "Insufficient disk space"
        exit 1
    fi

    success_log "Prerequisites check passed"
}

main_update() {
    info_log "Starting PrepperPi content update..."

    if [[ -f "$LOCK_FILE" ]]; then
        error_log "Update already in progress (lock file: $LOCK_FILE)"
        exit 1
    fi

    echo $$ > "$LOCK_FILE"
    trap 'rm -f "$LOCK_FILE"; info_log "Done"' EXIT

    check_prerequisites
    download_zim_content
    download_pdf_content
    update_kiwix_library
    cleanup_content
    generate_content_report

    success_log "Content update completed!"
    echo
    echo "ZIM Files: $(ls "$KIWIX_DATA_DIR"/*.zim 2>/dev/null | wc -l)"
    echo "Storage Used: $(du -sh "$KIWIX_DATA_DIR" 2>/dev/null | cut -f1)"
}

case "${1:-update}" in
    "update")   main_update ;;
    "verify")
        cd "$KIWIX_DATA_DIR"
        for zim_file in *.zim; do
            [[ -f "$zim_file" ]] && verify_zim_integrity "$zim_file"
        done
        ;;
    "cleanup")  cleanup_content ;;
    "report")   generate_content_report; cat "$BASE_DIR/logs/content_report.txt" ;;
    "estimate") echo "Estimated download size: $(estimate_download_size)GB" ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [update|verify|cleanup|report|estimate|help]"
        ;;
    *)
        error_log "Unknown command: $1"
        exit 1
        ;;
esac
