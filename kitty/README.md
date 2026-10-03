# Kitty Glass Aero

Kitty kurulu değilse dağıtımınızın paket yöneticisinden `kitty` paketini kurun:

| Dağıtım | Komut |
| --- | --- |
| Void | `sudo xbps-install -S kitty` |
| Arch | `sudo pacman -S kitty` |
| Debian / Ubuntu | `sudo apt install kitty` |
| Fedora | `sudo dnf install kitty` |

Glass-Aero-KDE klasöründe:

```sh
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/kitty"
cp kitty/glass-aero.conf "${XDG_CONFIG_HOME:-$HOME/.config}/kitty/"
```

Mevcut `kitty.conf` dosyanızın yedeğini alın. Aynı dizindeki `kitty.conf` dosyasının sonuna ekleyin; dosya yoksa oluşturun:

```conf
include glass-aero.conf
```

Kitty'yi kapatıp açın. Ayar dosyası mevcut mavi cam görünümünü, `0.10` opaklığı ve `background_blur 20` ayarını içerir. KDE'de **Sistem Ayarları → Masaüstü Efektleri → Bulanıklık** açık olsun. Fish gerekmez. KDE kurulum/kaldırma scriptleri bu dosyaları uygulamaz.

[Kitty ayarları](https://sw.kovidgoyal.net/kitty/conf/), [Arch paketi](https://archlinux.org/packages/extra/x86_64/kitty/), [Debian paketi](https://packages.debian.org/trixie/kitty), [Fedora paketi](https://packages.fedoraproject.org/pkgs/kitty/kitty/).
