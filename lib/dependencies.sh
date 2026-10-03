#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Sourced by install.sh. Install only missing theme engines, never a desktop upgrade.

dependency_root() {
    if [ "$(id -u)" = 0 ]; then "$@"
    elif command -v sudo >/dev/null 2>&1; then sudo "$@"
    elif command -v doas >/dev/null 2>&1; then doas "$@"
    else printf '%s\n' 'Paket kurulumu için sudo veya doas gerekli.' >&2; return 1
    fi
}

dependency_manager() {
    if [ -f /run/ostree-booted ] && command -v rpm-ostree >/dev/null 2>&1; then
        printf '%s\n' rpm-ostree; return
    fi
    dependency_id=$(awk -F= '$1 == "ID" { gsub(/"/, "", $2); print $2; exit }' /etc/os-release 2>/dev/null || true)
    case "$dependency_id" in
        void) dependency_preferred=xbps-install ;;
        debian|ubuntu|neon|linuxmint|pop) dependency_preferred=apt-get ;;
        arch|manjaro|endeavouros|garuda|cachyos) dependency_preferred=pacman ;;
        fedora|rhel|centos|rocky|almalinux) dependency_preferred=dnf ;;
        opensuse*) dependency_preferred=zypper ;;
        alpine) dependency_preferred=apk ;;
        gentoo) dependency_preferred=emerge ;;
        nixos) dependency_preferred=nix ;;
        *) dependency_preferred= ;;
    esac
    if [ -n "$dependency_preferred" ] && command -v "$dependency_preferred" >/dev/null 2>&1; then
        printf '%s\n' "$dependency_preferred"; return
    fi
    for dependency_tool in xbps-install apt-get pacman dnf zypper apk emerge nix; do
        if command -v "$dependency_tool" >/dev/null 2>&1; then
            printf '%s\n' "$dependency_tool"; return
        fi
    done
    return 1
}

prepare_dependency_manager() {
    case $1 in
        xbps-install) dependency_root xbps-install -S ;;
        apt-get) dependency_root apt-get update ;;
        zypper) dependency_root zypper --non-interactive refresh ;;
        apk) dependency_root apk update ;;
        *) return 0 ;;
    esac
}

dependency_available() {
    case $1 in
        apt-get) apt-cache show "$2" >/dev/null 2>&1 ;;
        pacman) pacman -Si "$2" >/dev/null 2>&1 ;;
        dnf) dnf -q info --available "$2" >/dev/null 2>&1 ;;
        zypper) zypper --non-interactive search --match-exact --type package "$2" 2>/dev/null |
            grep -E "[|][[:space:]]*$2[[:space:]]*[|]" >/dev/null ;;
        xbps-install) xbps-query -R "$2" >/dev/null 2>&1 ;;
        apk) apk search -x "$2" 2>/dev/null | grep -E "^$2-" >/dev/null ;;
        *) return 1 ;;
    esac
}

dependency_package() {
    dependency_pm=$1
    dependency_component=$2
    case "$dependency_pm:$dependency_component" in
        xbps-install:kvantum|pacman:kvantum|dnf:kvantum|rpm-ostree:kvantum) dependency_candidates='kvantum' ;;
        apt-get:kvantum) dependency_candidates='qt6-style-kvantum qt-style-kvantum' ;;
        zypper:kvantum|apk:kvantum) dependency_candidates='kvantum-qt6' ;;
        xbps-install:aurorae|pacman:aurorae) dependency_candidates='aurorae kwin' ;;
        dnf:aurorae) dependency_candidates='aurorae kwin-common kwin' ;;
        apt-get:aurorae) dependency_candidates='kwin-style-aurorae kwin-common' ;;
        zypper:aurorae) dependency_candidates='aurorae6 kwin6' ;;
        apk:aurorae) dependency_candidates='aurorae kwin' ;;
        rpm-ostree:aurorae) dependency_candidates='aurorae' ;;
        emerge:kvantum) printf '%s\n' x11-themes/kvantum; return ;;
        emerge:aurorae) printf '%s\n' kde-plasma/aurorae; return ;;
        nix:kvantum) printf '%s\n' nixpkgs#kdePackages.qtstyleplugin-kvantum; return ;;
        nix:aurorae) printf '%s\n' nixpkgs#kdePackages.aurorae; return ;;
        *) return 1 ;;
    esac
    for dependency_candidate in $dependency_candidates; do
        if [ "$dependency_pm" = rpm-ostree ] || dependency_available "$dependency_pm" "$dependency_candidate"; then
            printf '%s\n' "$dependency_candidate"; return
        fi
    done
    return 1
}

install_dependency_for() {
    dependency_pm=$1
    dependency_component=$2
    dependency_selected=$(dependency_package "$dependency_pm" "$dependency_component") || {
        printf 'Depoda uygun paket bulunamadı: %s\n' "$dependency_component" >&2; return 1
    }
    printf 'Eksik bileşen kuruluyor: %s\n' "$dependency_selected"
    case "$dependency_pm" in
        xbps-install) dependency_root xbps-install -S -y "$dependency_selected" ;;
        apt-get) dependency_root apt-get install -y "$dependency_selected" ;;
        pacman) dependency_root pacman -S --noconfirm "$dependency_selected" ;;
        dnf) dependency_root dnf install -y "$dependency_selected" ;;
        zypper) dependency_root zypper --non-interactive install "$dependency_selected" ;;
        apk) dependency_root apk add "$dependency_selected" ;;
        emerge) dependency_root emerge --ask=n --oneshot "$dependency_selected" ;;
        rpm-ostree)
            dependency_root rpm-ostree install -y "$dependency_selected" || return 1
            printf '%s\n' 'Atomic sistem: oturumu değil bilgisayarı yeniden başlatıp kurulumu tekrar çalıştırın.' >&2
            return 1 ;;
        nix)
            # Pin the downloaded store path in the user profile and expose its Qt plugins.
            dependency_store=$(nix --extra-experimental-features 'nix-command flakes' build --no-link --print-out-paths "$dependency_selected") || return 1
            case "$dependency_store" in /nix/store/*) ;; *) return 1 ;; esac
            case "$dependency_store" in *[!a-zA-Z0-9/._+-]*) return 1 ;; esac
            nix --extra-experimental-features 'nix-command flakes' profile install "$dependency_store" || return 1
            for dependency_dir in "$dependency_store/lib/qt-6/plugins" "$dependency_store/lib/qt6/plugins" "$dependency_store/lib/qt/plugins"; do
                if [ -d "$dependency_dir" ]; then
                    glass_dependency_qt_roots="${glass_dependency_qt_roots:+$glass_dependency_qt_roots:}$dependency_dir"
                fi
            done ;;
        *) return 1 ;;
    esac
}
