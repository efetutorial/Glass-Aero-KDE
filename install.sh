#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
set -eu

fail() { printf '%s\n' "$*" >&2; exit 1; }
apply=1
auto_deps=1
for arg in "$@"; do
    case $arg in
        --no-apply) apply=0 ;;
        --no-deps) auto_deps=0 ;;
        *) fail 'Kullanım: sh install.sh [--no-apply] [--no-deps]' ;;
    esac
done
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
data="${XDG_DATA_HOME:-$HOME/.local/share}"
config="${XDG_CONFIG_HOME:-$HOME/.config}"
state="${XDG_STATE_HOME:-$HOME/.local/state}/glass-aero"

# XDG locations must be absolute; never install into a relative or root directory.
for dir in "$data" "$config" "$state"; do
    case "$dir" in /*) ;; *) fail 'XDG dizinleri tam yol olmalı.' ;; esac
    [ "$dir" != / ] || fail 'XDG dizini / olamaz.'
done
work=$(mktemp -d)
trap 'rm -rf "$work"' 0
trap 'exit 1' HUP INT TERM
decoration=org.kde.kwin.aurorae
glass_dependency_qt_roots=

probe_dependencies() {
    need_kvantum=1
    need_aurorae=1
    LC_ALL=C QT_QPA_PLATFORM=offscreen QT_STYLE_OVERRIDE=kvantum QT_DEBUG_PLUGINS=1 \
        QT_LOGGING_RULES='qt.core.plugin.*=true;qt.core.library=true' \
        "$probe" --help > "$work/qt-probe" 2>&1 || return 1
    if grep -E 'libkvantum.*" loaded library|loaded library.*libkvantum' "$work/qt-probe" >/dev/null; then
        need_kvantum=0
    fi
    
    # Obtain Qt plugin search directories from the application, not distro paths.
    awk '/checking directory path/ {
        n = split($0, part, "\"")
        if (n >= 3 && part[2] ~ /\/styles$/) {
            sub(/\/styles$/, "", part[2]); print part[2]
        }
    }' "$work/qt-probe" > "$work/plugin-dirs"
    classic=0
    modern=0
    while IFS= read -r dir; do
        for api in org.kde.kdecoration2 org.kde.kdecoration3; do
            [ ! -f "$dir/$api/org.kde.kwin.aurorae.so" ] || classic=1
            [ ! -f "$dir/$api/org.kde.kwin.aurorae.v2.so" ] || modern=1
        done
    done < "$work/plugin-dirs"
    if [ "$modern" = 1 ]; then decoration=org.kde.kwin.aurorae.v2; need_aurorae=0
    elif [ "$classic" = 1 ]; then decoration=org.kde.kwin.aurorae; need_aurorae=0
    fi
}

for tool in kwriteconfig6 kbuildsycoca6; do
    command -v "$tool" >/dev/null 2>&1 || fail "Gerekli KDE aracı bulunamadı: $tool"
done
if [ "$apply" = 1 ]; then
    command -v plasmashell >/dev/null 2>&1 || fail 'KDE Plasma 6 gerekli.'
    command -v plasma-apply-lookandfeel >/dev/null 2>&1 || fail 'KDE Plasma 6 gerekli.'
    command -v plasma-apply-colorscheme >/dev/null 2>&1 || fail 'KDE Plasma 6 gerekli.'
    # KWin's version command works headlessly; plasmashell can require a renderer.
    version=
    for tool in kwin_wayland kwin_x11; do
        if command -v "$tool" >/dev/null 2>&1; then
            if LC_ALL=C QT_QPA_PLATFORM=offscreen "$tool" --version > "$work/plasma-version" 2>/dev/null; then
                version=$(awk '/^kwin / { print $2; exit }' "$work/plasma-version")
                [ -z "$version" ] || break
            fi
        fi
    done
    case "$version" in 6.*) ;; *) fail "KDE Plasma 6 gerekli; bulunan sürüm: ${version:-bilinmiyor}" ;; esac

    # Ask a real Qt 6 KDE application to load Kvantum. This respects Qt wrappers,
    # QT_PLUGIN_PATH and store prefixes, and rejects Qt 5 or broken plugins.
    probe=
    for tool in kcmshell6 systemsettings6 systemsettings dolphin; do
        if command -v "$tool" >/dev/null 2>&1; then probe=$tool; break; fi
    done
    [ -n "$probe" ] || fail 'Qt stilini doğrulamak için Sistem Ayarları veya kcmshell6 gerekli.'
    probe_dependencies || true
    if [ "$auto_deps" = 0 ]; then
        [ "$need_kvantum" = 0 ] || fail 'Qt 6 Kvantum yüklenemedi.'
        [ "$need_aurorae" = 0 ] || fail 'Aurorae pencere dekorasyonu bulunamadı.'
    fi
fi

for src in plasma/look-and-feel/org.efe.glassaero plasma/desktoptheme/GlassAero aurorae/GlassAero Kvantum/GlassAero icons/GlassAeroIcons kwin/glass-aero-keep-blur; do
    [ -d "$root/$src" ] || fail "Paket eksik: $src"
done
[ -f "$root/colors/GlassAero.colors" ] || fail 'Renk dosyası eksik.'
[ -f "$root/lib/dependencies.sh" ] || fail 'Bağımlılık scripti eksik.'

# Complete the backup before changing any installed theme or configuration.
mkdir -p "$data/glass-aero/backups"
backup=$(mktemp -d "$data/glass-aero/backups/$(date +%Y%m%d-%H%M%S)-XXXXXX")
for file in kdeglobals kwinrc plasmarc kcminputrc ksplashrc dolphinrc systemsettingsrc plasma-workspace/env/glass-aero-qt.sh plasma-org.kde.plasma.desktop-appletsrc plasmashellrc Kvantum/kvantum.kvconfig kdedefaults/kdeglobals kdedefaults/kwinrc kdedefaults/plasmarc kdedefaults/kcminputrc kdedefaults/ksplashrc kdedefaults/package; do
    if [ -f "$config/$file" ]; then
        mkdir -p "$backup/config/$(dirname -- "$file")"
        cp -p "$config/$file" "$backup/config/$file"
    fi
done
if [ -d "$config/Kvantum/GlassAero" ]; then
    mkdir -p "$backup/config/Kvantum"
    cp -a "$config/Kvantum/GlassAero" "$backup/config/Kvantum/GlassAero"
fi
for path in plasma/look-and-feel/org.efe.glassaero plasma/desktoptheme/GlassAero aurorae/themes/GlassAero icons/GlassAeroIcons kwin/effects/glass-aero-keep-blur color-schemes/GlassAero.colors; do
    if [ -e "$data/$path" ]; then
        mkdir -p "$backup/data/$(dirname -- "$path")"
        cp -a "$data/$path" "$backup/data/$path"
    fi
done
printf '%s\n' complete > "$backup/complete"
printf 'Yedek: %s\n' "$backup"

if [ "$apply" = 1 ] && { [ "$need_kvantum" = 1 ] || [ "$need_aurorae" = 1 ]; }; then
    . "$root/lib/dependencies.sh"
    manager=$(dependency_manager) || fail 'Desteklenen paket yöneticisi bulunamadı.'
    prepare_dependency_manager "$manager" || fail 'Paket deposu kontrolü başarısız; tema uygulanmadı.'
    if [ "$need_kvantum" = 1 ]; then
        install_dependency_for "$manager" kvantum || fail 'Kvantum kurulamadı; tema uygulanmadı.'
    fi
    if [ "$need_aurorae" = 1 ]; then
        install_dependency_for "$manager" aurorae || fail 'Aurorae kurulamadı; tema uygulanmadı.'
    fi
    if [ -n "$glass_dependency_qt_roots" ]; then
        export QT_PLUGIN_PATH="$glass_dependency_qt_roots${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
    fi
    probe_dependencies || fail 'Kurulum sonrası Qt kontrolü başarısız; tema uygulanmadı.'
    [ "$need_kvantum" = 0 ] || fail 'Kvantum yüklenemedi; tema uygulanmadı.'
    [ "$need_aurorae" = 0 ] || fail 'Aurorae bulunamadı; tema uygulanmadı.'
fi
mkdir -p "$state"
if [ ! -f "$state/installed" ]; then
    printf '%s\n' "$backup" > "$state/original-backup"
fi

copy_tree() {
    mkdir -p "$2"
    cp -a "$root/$1/." "$2/"
}
copy_tree plasma/look-and-feel/org.efe.glassaero "$data/plasma/look-and-feel/org.efe.glassaero"
# Keep GUI re-application consistent with the detected Aurorae implementation.
kwriteconfig6 --file "$data/plasma/look-and-feel/org.efe.glassaero/contents/defaults" \
    --group kwinrc --group org.kde.kdecoration2 --key library "$decoration"
copy_tree plasma/desktoptheme/GlassAero "$data/plasma/desktoptheme/GlassAero"
copy_tree aurorae/GlassAero "$data/aurorae/themes/GlassAero"
copy_tree Kvantum/GlassAero "$config/Kvantum/GlassAero"
copy_tree icons/GlassAeroIcons "$data/icons/GlassAeroIcons"
copy_tree kwin/glass-aero-keep-blur "$data/kwin/effects/glass-aero-keep-blur"
mkdir -p "$data/color-schemes"
cp "$root/colors/GlassAero.colors" "$data/color-schemes/GlassAero.colors"
printf '%s\n' '1.0.0' > "$state/installed"

if [ -n "$glass_dependency_qt_roots" ]; then
    mkdir -p "$config/plasma-workspace/env"
    printf '#!/bin/sh\nexport QT_PLUGIN_PATH="%s${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"\n' "$glass_dependency_qt_roots" > "$config/plasma-workspace/env/glass-aero-qt.sh"
    chmod +x "$config/plasma-workspace/env/glass-aero-qt.sh"
fi

kwriteconfig6 --file "$config/Kvantum/kvantum.kvconfig" --group General --key theme GlassAero
if [ "$apply" = 1 ]; then
    plasma-apply-lookandfeel --apply org.efe.glassaero
    plasma-apply-colorscheme GlassAero
    kwriteconfig6 --file "$config/kdeglobals" --group KDE --key widgetStyle kvantum
    kwriteconfig6 --file "$config/kdeglobals" --group KDE --key LookAndFeelPackage org.efe.glassaero
    kwriteconfig6 --file "$config/kdeglobals" --group Icons --key Theme GlassAeroIcons
    kwriteconfig6 --file "$config/plasmarc" --group Theme --key name GlassAero
    kwriteconfig6 --file "$config/kwinrc" --group org.kde.kdecoration2 --key library "$decoration"
    kwriteconfig6 --file "$config/kwinrc" --group org.kde.kdecoration2 --key theme __aurorae__svg__GlassAero
    kwriteconfig6 --file "$config/kwinrc" --group Plugins --key blurEnabled true
    kwriteconfig6 --file "$config/kwinrc" --group Plugins --key wobblywindowsEnabled true
    kwriteconfig6 --file "$config/dolphinrc" --group UiSettings --key ColorScheme GlassAero
    kwriteconfig6 --file "$config/systemsettingsrc" --group UiSettings --key ColorScheme GlassAero
fi
kbuildsycoca6
printf '%s\n' 'Glass Aero kuruldu. Oturumu kapatıp açın.'
