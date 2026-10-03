# Compatibility checks

Target: an existing KDE Plasma 6 desktop, native Qt 6 Kvantum, Aurorae and GNU/BusyBox-style Linux file utilities. Missing engines are installed using the distribution package manager. No precompiled Qt plugin is bundled. Kitty/Fish/Firefox are not installed or configured.

- Actual environment: Void Linux, Plasma 6.7.5, Qt 6.11.2, `/bin/sh` = dash.
- Native Qt 6 loaded the installed Kvantum library using its own plugin search paths. The installer selected Aurorae v2 and wrote matching global-theme defaults.
- Full installation and removal were tested with isolated XDG directories containing spaces. No live desktop theme was changed by these tests.
- Tested backup before changes, retained original backup across reinstalls, restoration of previous settings/assets, retained backups after removal, and abort on backup failure.
- Installer logic was tested with simulated `/usr/lib/qt6`, Debian multiarch, Fedora `/usr/lib64`, ARM64 and Nix store prefixes; both classic and v2 Aurorae were checked, along with rejection of Plasma 5, missing engines and relative XDG paths. These were logic tests, not actual distribution/VM tests.
- Shell syntax checked with dash and Bash POSIX mode; metadata, SVG and JavaScript checked separately.
- Actual privileged Void installation: the installer completed its backup, refreshed repositories, downloaded and installed `kvantum-1.1.8_1`, `qt5-svg` and `qt5-x11extras`, then loaded the system Qt 6 Kvantum plugin and applied the theme in isolated XDG directories. Uninstallation restored the isolated configuration successfully. No existing system packages were upgraded or removed; Aurorae was already installed.
- Actual nested KWin Wayland desktop: installed into isolated XDG directories and a separate D-Bus session, launched KWin's virtual output, Plasma Shell and Dolphin, captured and visually inspected a screenshot. The panel, Aero decoration and application style rendered and Dolphin stayed running.
- The optional `kitty/glass-aero.conf` was parsed successfully by Kitty 0.48.2's native configuration loader; opacity 0.10 and blur 20 were verified. It is distributed with a manual guide and is never applied by the shell scripts.
- Package selection/commands for XBPS, APT, Pacman, DNF, Zypper, APK, Portage and Nix were checked with mock commands, including an atomic deployment requiring reboot, unavailable packages and command failures.
- Automatic installation checks verified that the backup completes before repository refresh, missing engines are installed and rechecked, existing engines skip installation, and failed/broken installations leave the theme unapplied. Package commands were mocked; KConfig writes were real and isolated.

Actual Arch, Debian, Ubuntu, Fedora, openSUSE, NixOS and VM desktops have not been tested. Flatpak apps, declaratively managed read-only configuration, Plasma 5 and guaranteed blur on every GPU/compositor are outside the validated setup.

Package references: [Kvantum upstream](https://github.com/tsujan/Kvantum/blob/master/Kvantum/INSTALL.md), [Debian Aurorae in kwin-common](https://packages.debian.org/trixie/amd64/kwin-common/filelist), [Arch Aurorae](https://archlinux.org/packages/extra/x86_64/aurorae/), [Fedora Aurorae](https://packages.fedoraproject.org/pkgs/aurorae/aurorae/), [Gentoo](https://packages.gentoo.org/packages/kde-plasma/aurorae), [Alpine Qt 6 Kvantum](https://pkgs.alpinelinux.org/package/edge/community/aarch64/kvantum-qt6).
