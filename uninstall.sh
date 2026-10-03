#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
set -eu
data="${XDG_DATA_HOME:-$HOME/.local/share}"
config="${XDG_CONFIG_HOME:-$HOME/.config}"
state="${XDG_STATE_HOME:-$HOME/.local/state}/glass-aero"
for dir in "$data" "$config" "$state"; do
    case "$dir" in /*) ;; *) printf '%s\n' 'XDG dizinleri tam yol olmalı.' >&2; exit 1 ;; esac
    [ "$dir" != / ] || { printf '%s\n' 'XDG dizini / olamaz.' >&2; exit 1; }
done
[ -f "$state/installed" ] || { printf '%s\n' 'Glass Aero kurulumu bulunamadı.'; exit 1; }

original=
if [ -f "$state/original-backup" ]; then
    original=$(cat "$state/original-backup")
    [ -f "$original/complete" ] || { printf '%s\n' 'İlk kurulum yedeği bulunamadı; kaldırma durduruldu.' >&2; exit 1; }
    before="$original/config"
    files='kdeglobals kwinrc plasmarc kcminputrc ksplashrc dolphinrc systemsettingsrc plasma-workspace/env/glass-aero-qt.sh plasma-org.kde.plasma.desktop-appletsrc plasmashellrc Kvantum/kvantum.kvconfig kdedefaults/kdeglobals kdedefaults/kwinrc kdedefaults/plasmarc kdedefaults/kcminputrc kdedefaults/ksplashrc kdedefaults/package'
else
    # Compatibility with installations made by the first installer version.
    before="$state/before"
    files='kdeglobals kwinrc plasmarc kcminputrc ksplashrc dolphinrc systemsettingsrc Kvantum/kvantum.kvconfig kdedefaults/kdeglobals kdedefaults/kwinrc kdedefaults/plasmarc kdedefaults/kcminputrc kdedefaults/ksplashrc kdedefaults/package'
fi

# Restore the first installation, rather than a later reinstall of Glass Aero.
for file in $files; do
    if [ -f "$before/$file" ]; then
        mkdir -p "$config/$(dirname -- "$file")"
        cp -p "$before/$file" "$config/$file"
    else
        rm -f "$config/$file"
    fi
done

rm -rf "$data/plasma/look-and-feel/org.efe.glassaero" \
    "$data/plasma/desktoptheme/GlassAero" "$data/aurorae/themes/GlassAero" \
    "$config/Kvantum/GlassAero" "$data/icons/GlassAeroIcons" \
    "$data/kwin/effects/glass-aero-keep-blur"
rm -f "$data/color-schemes/GlassAero.colors"
if [ -n "$original" ]; then
    if [ -d "$before/Kvantum/GlassAero" ]; then
        mkdir -p "$config/Kvantum"
        cp -a "$before/Kvantum/GlassAero" "$config/Kvantum/GlassAero"
    fi
    for path in plasma/look-and-feel/org.efe.glassaero plasma/desktoptheme/GlassAero aurorae/themes/GlassAero icons/GlassAeroIcons kwin/effects/glass-aero-keep-blur color-schemes/GlassAero.colors; do
        if [ -e "$original/data/$path" ]; then
            mkdir -p "$data/$(dirname -- "$path")"
            cp -a "$original/data/$path" "$data/$path"
        fi
    done
fi
rm -rf "$state"
if command -v kbuildsycoca6 >/dev/null 2>&1; then kbuildsycoca6; fi
printf '%s\n' 'Glass Aero kaldırıldı. Oturumu kapatıp açın.'
