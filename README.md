# wallp

Wallpaper para **GNOME/Wayland** (Arch), com rotação automática e grade 21:9.

![ícone](icon.svg)

## Instalar

```sh
install -Dm755 wallp ~/.local/bin/wallp
install -Dm644 icon.svg ~/.local/share/icons/hicolor/scalable/apps/io.wallp.App.svg
install -Dm644 io.wallp.App.desktop ~/.local/share/applications/io.wallp.App.desktop
gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor
```

Dependências: `python3` + `pygobject` (já vem com o GNOME). Sem `requests`,
sem `PIL`, sem `node`.

## Uso

```sh
wallp                     # abre a janela
wallp --rotate            # só a rotação, sem janela (para o systemd)
wallp --key <APIKEY>      # grava a key em ~/.config/wallp/config.json (0600)
wallp --pasta <caminho>   # grava a pasta
wallp --boot on|off       # instala/desinstala a rotação no boot
wallp --status            # mostra o estado atual
```

A key também vem de `WALLP_KEY`, que tem precedência sobre o arquivo e não
grava nada em disco:

```sh
WALLP_KEY=xxx wallp
```

## Fontes, em ordem de prioridade

1. **Local** — imagens da pasta apontada no topo
2. **Web** — wallhaven.cc via API key, **só `nsfw` + `sketchy`**

A rotação automática usa **apenas a pasta local** — nada de rede durante a
troca.

## Teclado

| tecla | ação |
|---|---|
| setas / <kbd>Enter</kbd> | navegar e aplicar |
| <kbd>R</kbd> | sortear outro lote da web |
| <kbd>V</kbd> | alternar lista / grade |
| <kbd>N</kbd> | próximo wallpaper da pasta |
| <kbd>Ctrl+Q</kbd> | sair de verdade |

## Relógio e rotação

O ícone de relógio no canto superior direito abre o popup de rotação:

- **checkbox** liga/desliga a troca automática
- o **spin** logo abaixo define o intervalo, em **segundos** ou **minutos**
- o ponteiro do relógio completa uma volta por intervalo, então mostra a
  progresso da contagem — para de girar quando a rotação está desligada

**Escolha manual desliga a rotação.** Clicar numa imagem da lista tem
prioridade: se a rotação estava ligada, ela desliga de vez, senão o próximo
tick sobrescreveria o seu clique. O botão *próximo* (tecla `N`) não desliga.

## Grade

Células em **21:9** (mais larga que alta), com `ContentFit.COVER` — preenche a
célula e corta o excesso, sem distorcer. As colunas são responsivas, com teto
de `GRID_COLS_MAX`; escolhe sempre a maior célula que ainda caiba inteira, então
nunca aparece barra horizontal.

## O filtro 18+

O parâmetro `purity` da API do wallhaven **está quebrado**: devolve o mesmo
lote para `sfw`, `sketchy` e `nsfw` (e `categories` também não filtra). Por
isso o app não confia no servidor — cada item é conferido no cliente e só entra
se `purity in {nsfw, sketchy}`.

## Bandeja e boot

Ao fechar a janela, o app **esconde** e a rotação continua.

A bandeja precisa da extensão **AppIndicator**. Sem ela, o `AppIndicator` é
criado mas não aparece em lugar nenhum. Para reabrir a janela: rode `wallp`
de novo (instância única). Para encerrar: `pkill -f wallp` ou <kbd>Ctrl+Q</kbd>.

`wallp --boot on` grava um unit em `~/.config/systemd/user/wallp.service` que
roda `wallp --rotate` e habilita `linger`, para voltar no boot sem sessão
gráfica aberta.

## Arquivos

| caminho | conteúdo |
|---|---|
| `~/.config/wallp/config.json` | pasta, key, intervalo, view — modo `0600` |
| `~/.cache/wallp/<id>.jpg` | miniaturas da web (~20 KB) |
| `~/.cache/wallp/local/<hash>.jpg` | miniaturas locais, invalidado por mtime |
| `~/.cache/wallp/<id>.<ext>` | imagem em resolução original, ao aplicar |

O `config.json` **não** é versionado — ver `.gitignore`.

## Memória

Medido nesta máquina:

| modo | RSS |
|---|---|
| `wallp --rotate` (daemon, sem Gtk) | **~35 MB** |
| janela GTK4, lista carregada | ~250 MB |

O GTK4 via PyGObject custa ~200 MB no `import` sozinho, antes de qualquer
widget — nenhuma otimização aqui muda isso. Por isso o daemon do systemd **não
carrega o Gtk**: usa só o GLib. Na janela, o app força `GSK_RENDERER=cairo`
(economiza ~18 MB; o padrão cai em llvmpipe sem DRI3).

## Licença

MIT
