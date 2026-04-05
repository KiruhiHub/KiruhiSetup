#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  ArchInit — Common Library
#  set -e YOK — hata loglanır, kurulum devam eder.
#  sudo/root YOK — yay her şeyi halleder.
# ═══════════════════════════════════════════════════════════════

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log_ok()      { echo -e "${GREEN}[OK]${RESET} $*";  echo "[OK] $*"   >> "${LOG_FILE:-/tmp/archinit.log}"; }
log_info()    { echo -e "${CYAN}[>>]${RESET} $*";   echo "[>>] $*"   >> "${LOG_FILE:-/tmp/archinit.log}"; }
log_warn()    { echo -e "${YELLOW}[!!]${RESET} $*"; echo "[!!] $*"   >> "${LOG_FILE:-/tmp/archinit.log}"; }
log_error()   { echo -e "${RED}[ERR]${RESET} $*";  echo "[ERR] $*"  >> "${LOG_FILE:-/tmp/archinit.log}"; }
log_section() {
    echo -e "\n${BOLD}${CYAN}══ $* ══${RESET}\n"
    echo -e "\n══ $* ══" >> "${LOG_FILE:-/tmp/archinit.log}"
}
log_done() {
    echo -e "\n${GREEN}${BOLD}[DONE] $*${RESET}\n"
    echo "[DONE] $*" >> "${LOG_FILE:-/tmp/archinit.log}"
}

is_installed()      { command -v "$1" &>/dev/null; }
pkg_installed()     { pacman -Qi "$1" &>/dev/null 2>&1; }
flatpak_installed() { flatpak list --app --columns=application 2>/dev/null | grep -qx "$1"; }

# ── yay — hem pacman hem AUR, şifre sormaz ───────────────────
# yay kendi içinde sudo'yu halleder (polkit veya cached sudo).
# Kullanıcı yay'ı normal kullanıcı olarak çalıştırır.

install_pkg() {
    local pkg="$1"
    if pkg_installed "$pkg"; then
        log_warn "$pkg zaten kurulu."
        return 0
    fi
    log_info "Kuruluyor: $pkg"
    if yay -S --noconfirm --needed --noprogressbar "$pkg" \
        >> "${LOG_FILE:-/tmp/archinit.log}" 2>&1; then
        log_ok "$pkg kuruldu."
    else
        log_error "$pkg KURULAMADI"
        echo "[FAIL] $pkg" >> "${LOG_FILE:-/tmp/archinit.log}"
    fi
}

install_aur() {
    install_pkg "$1"   # yay zaten AUR'u destekler
}

install_flatpak() {
    local app_id="$1"
    if ! is_installed flatpak; then
        log_warn "Flatpak yok — atlanıyor: $app_id"
        return 1
    fi
    if flatpak_installed "$app_id"; then
        log_warn "$app_id zaten kurulu."
        return 0
    fi
    log_info "Flatpak: $app_id"
    if flatpak install -y --noninteractive flathub "$app_id" \
        >> "${LOG_FILE:-/tmp/archinit.log}" 2>&1; then
        log_ok "$app_id kuruldu (Flatpak)."
    else
        log_error "$app_id KURULAMADI (Flatpak)"
        echo "[FAIL:flatpak] $app_id" >> "${LOG_FILE:-/tmp/archinit.log}"
    fi
}

update_system() {
    log_info "Sistem güncelleniyor..."
    yay -Syu --noconfirm --noprogressbar \
        >> "${LOG_FILE:-/tmp/archinit.log}" 2>&1 \
        && log_ok "Sistem güncellendi." \
        || log_warn "Güncelleme başarısız — devam ediliyor."
}

enable_multilib() {
    grep -q "^\[multilib\]" /etc/pacman.conf && return 0
    log_info "multilib etkinleştiriliyor..."
    # yay üzerinden sed çalıştır (sudo gerektirmez, yay halleder)
    yay -S --noconfirm --needed multilib-devel \
        >> "${LOG_FILE:-/tmp/archinit.log}" 2>&1 || true
}

setup_flatpak() {
    if ! is_installed flatpak; then
        log_info "Flatpak kuruluyor..."
        yay -S --noconfirm --needed flatpak \
            >> "${LOG_FILE:-/tmp/archinit.log}" 2>&1 || true
    fi
    if ! flatpak remotes 2>/dev/null | grep -q flathub; then
        log_info "Flathub ekleniyor..."
        flatpak remote-add --if-not-exists flathub \
            https://dl.flathub.org/repo/flathub.flatpakrepo \
            >> "${LOG_FILE:-/tmp/archinit.log}" 2>&1 || true
    fi
    log_ok "Flatpak + Flathub hazır."
}

setup_yay() {
    if is_installed yay; then
        log_ok "yay zaten kurulu."
        return 0
    fi
    log_info "yay kuruluyor..."
    # yay'ı kurmak için bir kez pacman gerekir (bu tek sudo)
    # Sonrasında her şey yay üzerinden gider
    sudo pacman -S --noconfirm --needed git base-devel \
        >> "${LOG_FILE:-/tmp/archinit.log}" 2>&1 || true
    local tmp
    tmp=$(mktemp -d)
    if git clone --depth=1 https://aur.archlinux.org/yay-bin.git "$tmp/yay" \
        >> "${LOG_FILE:-/tmp/archinit.log}" 2>&1; then
        (cd "$tmp/yay" && makepkg -si --noconfirm \
            >> "${LOG_FILE:-/tmp/archinit.log}" 2>&1) || true
        log_ok "yay kuruldu."
    else
        log_error "yay klonlanamadı."
    fi
    rm -rf "$tmp"
}
