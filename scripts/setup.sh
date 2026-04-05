#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  ArchInit — Ana Kurulum Betiği
#  sudo/root YOK — yay her şeyi halleder.
#  Arkaplanda çalışır, loglar /tmp/archinit_*.log dosyasına.
# ═══════════════════════════════════════════════════════════════

PROFILE=""
DRIVERS=false
CLOUD="none"
APPS=""
AUR=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile) PROFILE="$2"; shift 2 ;;
        --drivers) DRIVERS=true; shift ;;
        --cloud)   CLOUD="$2";   shift 2 ;;
        --apps)    APPS="$2";    shift 2 ;;
        --aur)     AUR=true;     shift ;;
        *)         shift ;;
    esac
done

export LOG_FILE="/tmp/archinit_$(date +%Y%m%d_%H%M%S).log"

source "$SCRIPT_DIR/lib/common.sh"

# Log başlığı
{
    echo "══════════════════════════════════════"
    echo "  ArchInit — $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  Profil : $PROFILE"
    echo "  Bulut  : $CLOUD"
    echo "  PID    : $$"
    echo "══════════════════════════════════════"
} > "$LOG_FILE"

echo "[ARCHINIT] Log: $LOG_FILE"
echo "[ARCHINIT] PID: $$"

if [[ -z "$PROFILE" ]]; then
    log_error "Profil belirtilmedi."
    exit 1
fi

# ── yay zorunlu ───────────────────────────────────────────────
if ! is_installed yay; then
    log_info "yay bulunamadı, kuruluyor..."
    setup_yay
fi

# ── Donanım tespiti ───────────────────────────────────────────
detect_hardware() {
    log_section "Donanım"

    if [[ -d /sys/class/power_supply/BAT0 ]] || [[ -d /sys/class/power_supply/BAT1 ]]; then
        log_info "Laptop — TLP kuruluyor..."
        install_pkg "tlp"
        install_pkg "tlp-rdw"
        # systemctl enable için yay --sudoloop kullanır
        yay -S --noconfirm --needed tlp >> "$LOG_FILE" 2>&1 || true
    fi

    if lspci 2>/dev/null | grep -qi "nvidia" && [[ "$DRIVERS" == "true" ]]; then
        install_pkg "nvidia"
        install_pkg "nvidia-utils"
    elif lspci 2>/dev/null | grep -qi "amd\|radeon"; then
        install_pkg "mesa"
        install_pkg "vulkan-radeon"
    elif lspci 2>/dev/null | grep -qi "intel"; then
        install_pkg "mesa"
        install_pkg "vulkan-intel"
    fi
}

# ── Bulut servisi ─────────────────────────────────────────────
setup_cloud() {
    [[ "$CLOUD" == "none" ]] || [[ -z "$CLOUD" ]] && return 0
    log_section "Bulut: $CLOUD"

    install_pkg "rclone"

    local mount_dir="$HOME/Cloud/$CLOUD"
    mkdir -p "$mount_dir"

    local svc_dir="$HOME/.config/systemd/user"
    mkdir -p "$svc_dir"

    cat > "$svc_dir/rclone-${CLOUD}.service" <<EOF
[Unit]
Description=rclone — $CLOUD
After=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/rclone mount ${CLOUD}: ${mount_dir} --vfs-cache-mode writes --vfs-cache-max-size 512M
ExecStop=/bin/fusermount -u ${mount_dir}
Restart=on-failure

[Install]
WantedBy=default.target
EOF
    systemctl --user daemon-reload >> "$LOG_FILE" 2>&1 || true
    log_ok "rclone servisi hazır → $mount_dir"
}

# ── Profil ────────────────────────────────────────────────────
run_profile() {
    case "$PROFILE" in
        yazilimci|developer|dev)
            bash "$SCRIPT_DIR/profiles/developer.sh" ;;
        gunluk|daily)
            bash "$SCRIPT_DIR/profiles/daily.sh" ;;
        ozel|custom)
            export CUSTOM_APPS="$APPS"
            bash "$SCRIPT_DIR/profiles/custom.sh" ;;
        *)
            log_error "Bilinmeyen profil: $PROFILE"; exit 1 ;;
    esac
}

# ── Özet ──────────────────────────────────────────────────────
print_summary() {
    local fails
    fails=$(grep -c "^\[FAIL" "$LOG_FILE" 2>/dev/null || echo 0)
    echo ""
    echo "══════════════════════════════════════"
    echo "  Tamamlandı — $(date '+%H:%M:%S')"
    echo "  Log: $LOG_FILE"
    [[ "$fails" -gt 0 ]] \
        && echo "  Uyarı: $fails paket kurulamadı" \
        || echo "  Durum: Başarılı"
    echo "══════════════════════════════════════"
    [[ "$fails" -gt 0 ]] \
        && echo "[ARCHINIT:DONE:WARN] $fails başarısız" \
        || echo "[ARCHINIT:DONE:OK] Kurulum tamamlandı"
}

# ── Ana akış ──────────────────────────────────────────────────
main() {
    log_section "ArchInit Başlatılıyor"
    detect_hardware
    run_profile
    setup_cloud
    print_summary
}

main
