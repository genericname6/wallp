#!/usr/bin/env bash
# wallp — instalador (Arch Linux)
#
#   ./install.sh            instala em ~/.local
#   ./install.sh --uninstall remove tudo (mantem ~/.config/wallp)
#
# Nao instala a API key nem a pasta: rode depois
#   wallp --key <APIKEY>
#   wallp --pasta ~/Imagens/wallpapers
#   wallp --boot on         (opcional: rotacao no boot)
set -euo pipefail

PREFIX="${HOME}/.local"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

have() { command -v "$1" >/dev/null 2>&1; }

uninstall() {
    rm -f "${PREFIX}/bin/wallp"
    rm -f "${PREFIX}/share/icons/hicolor/scalable/apps/io.wallp.App.svg"
    rm -f "${PREFIX}/share/applications/io.wallp.App.desktop"
    have gtk-update-icon-cache && \
        gtk-update-icon-cache -f -t "${PREFIX}/share/icons/hicolor" >/dev/null 2>&1 || true
    echo "wallp desinstalado (config em ~/.config/wallp mantido)."
    exit 0
}

[ "${1:-}" = "--uninstall" ] && uninstall

echo "== wallp: checando dependencias =="
falta=()

# python3
if have python3; then echo "  ok  python3 $(python3 --version 2>&1 | cut -d' ' -f2)"; else falta+=(python); fi

# pygobject + GTK4 + GdkPixbuf (o que o app importa de verdade)
if python3 -c "import gi; gi.require_version('Gtk','4.0'); gi.require_version('GdkPixbuf','2.0'); from gi.repository import Gtk, GdkPixbuf" 2>/dev/null; then
    echo "  ok  pygobject + GTK4 + GdkPixbuf"
else
    falta+=(python-gobject gtk4 gdk-pixbuf2)
fi

# ImageMagick (fallback do glycin: 10 dos 29 PNGs 5K nao abrem sem ele)
if have magick || have convert; then echo "  ok  imagemagick"; else falta+=(imagemagick); fi

# GNOME (aplica via gsettings) — avisa, nao exige: sem ele o app abre mas nao aplica
if have gsettings; then echo "  ok  gsettings"; else echo "  AVISO  gsettings ausente (sem GNOME nao aplica wallpaper)"; fi

# systemd --user (so para wallp --boot)
if have systemctl && have loginctl; then echo "  ok  systemd (boot opcional)"; else echo "  AVISO  sem systemd: wallp --boot indisponivel"; fi

# cache de icones
if have gtk-update-icon-cache; then echo "  ok  gtk-update-icon-cache"; else falta+=(gtk4); fi

if [ "${#falta[@]}" -gt 0 ]; then
    # dedup
    pkgs=$(printf '%s\n' "${falta[@]}" | sort -u | tr '\n' ' ')
    echo
    echo "Faltando: ${pkgs}"
    if have sudo; then
        echo "Instalando via pacman..."
        sudo pacman -S --needed --noconfirm ${pkgs}
    else
        echo "Sem sudo. Rode como root:"
        echo "  pacman -S --needed ${pkgs}"
        exit 1
    fi
fi

echo
echo "== instalando arquivos em ${PREFIX} =="
install -Dm755 "${REPO}/wallp"                                "${PREFIX}/bin/wallp"
install -Dm644 "${REPO}/icon.svg"                             "${PREFIX}/share/icons/hicolor/scalable/apps/io.wallp.App.svg"
install -Dm644 "${REPO}/io.wallp.App.desktop"                 "${PREFIX}/share/applications/io.wallp.App.desktop"
# o .desktop do repo usa Exec generico; garante o caminho absoluto
sed -i "s|^Exec=.*|Exec=${PREFIX}/bin/wallp|"                   "${PREFIX}/share/applications/io.wallp.App.desktop"
gtk-update-icon-cache -f -t "${PREFIX}/share/icons/hicolor" >/dev/null 2>&1 || true

echo
echo "== verificando =="
"${PREFIX}/bin/wallp" --help >/dev/null 2>&1 && echo "  ok  wallp responde" || { echo "  FALHOU: wallp nao executa"; exit 1; }
python3 -m py_compile "${PREFIX}/bin/wallp" && echo "  ok  sintaxe"

echo
echo "Pronto. Proximos passos:"
echo "  wallp --key <APIKEY>      # https://wallhaven.cc/account/settings/api"
echo "  wallp --pasta ~/Imagens/wallpapers"
echo "  wallp                     # abre"
echo "  wallp --boot on           # opcional: rotacao no boot"
