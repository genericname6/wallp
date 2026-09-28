# wallp

Wallpaper para **GNOME/Wayland** (Arch), com rotação automática.

## Fontes, em ordem de prioridade

1. **Local** — imagens da pasta apontada no topo
2. **Web** — wallhaven.cc via API key, **só `nsfw` + `sketchy`**

A rotação automática usa **apenas a pasta local** — nada de rede durante a
troca.

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
grava nada em disco.

## Teclado

| tecla | ação |
|---|---|
| <kbd>Enter</kbd> / duplo clique | aplicar o wallpaper |
| <kbd>R</kbd> | sortear outro lote da web |
| <kbd>N</kbd> | próximo wallpaper da pasta |
| <kbd>Ctrl+Q</kbd> | sair de verdade |

## Relógio e rotação

O ícone de relógio no canto superior direito abre o popup de rotação:

- **checkbox** liga/desliga a troca automática
- o **spin** logo abaixo define o intervalo, em **segundos** ou **minutos**
  (minimo 5 segundos: abaixo disso o PC congela -- cada troca sao 2
  processos, decode de MBs e crossfade em tela cheia, tudo na CPU)
- o ponteiro do relógio completa uma volta por intervalo, então ele mostra a
  progresso da contagem — para de girar quando a rotação está desligada

**Escolha manual desliga a rotação.** Clicar numa imagem da grade tem
prioridade: se a rotação estava ligada, ela desliga de vez, senão o próximo
tick sobrescreveria o seu clique. O botão *próximo* (tecla `N`) não desliga.

## Grade

Única view do app (a lista foi removida). Células em **21:9** (mais larga
que alta), com `ContentFit.COVER` — preenche a célula e corta o excesso,
sem distorcer. As colunas são responsivas: quantas cabem na largura real
da janela, com teto de 6. Escolhe sempre a **maior célula** que ainda
caiba inteira, então nunca aparece barra horizontal. Os locais ficam
primeiro, a web (com etiqueta `nsfw`/`sketchy`) depois.

**Botão direito** num wallpaper da web abre **Baixar para a pasta**: salva
o original na pasta do topo (ou `~/Pictures/wallpapers`, criada se preciso)
e o arquivo entra na grade na hora.

**Busca na web**: o campo ao lado da pasta filtra por termo (Enter busca,
limpar + Enter volta ao aleatório). O R respeita a busca ativa. O filtro
18+ continua valendo, então o lote pode vir menor.

## O filtro 18+

O parâmetro `purity` da API do wallhaven **está quebrado**: devolve o mesmo
lote para `sfw`, `sketchy` e `nsfw` (e `categories` também não filtra). Por
isso o app não confia no servidor — cada item é conferido no cliente e só entra
se `purity in {nsfw, sketchy}`.

## Bandeja e boot

Ao fechar a janela, o app **esconde** e a rotação continua.

A bandeja precisa da extensão **AppIndicator**, que não está instalada nesta
máquina — até lá, o `AppIndicator` é criado mas não aparece em lugar nenhum.
Para reabrir a janela: rode `wallp` de novo (instância única) ou
`pkill -f wallp` para encerrar.

`wallp --boot on` grava um unit em `~/.config/systemd/user/wallp.service` que
roda `wallp --rotate` e habilita `linger`, para voltar no boot sem sessão
gráfica aberta.

## Arquivos

| caminho | conteúdo |
|---|---|
| `~/.config/wallp/config.json` | pasta, key, intervalo, limite do cache — modo `0600` |
| `~/.cache/wallp/<id>_lg.jpg` | miniaturas da web (~30 KB) |
| `~/.cache/wallp/local/<hash>.jpg` | miniaturas locais |
| `~/.cache/wallp/<id>_full.<ext>` | original aplicado da web |

## Limite do cache

Os originais aplicados ficam no cache e cresciam sem limite (468 MB
medidos). Depois de cada aplicação da web, o app apaga os mais antigos
até caber em `cache_limit_mb` (padrão 100) — nunca o recém-aplicado, nunca
o que o GNOME aponta, nunca os thumbs. `wallp --status` mostra o uso.
| `~/.local/share/icons/hicolor/scalable/apps/io.wallp.App.svg` | ícone |
| `~/.local/share/applications/io.wallp.App.desktop` | entrada do menu de apps |

Desinstalar:

```sh
rm ~/.local/bin/wallp ~/.config/wallp/config.json
rm -rf ~/.cache/wallp
rm ~/.local/share/icons/hicolor/scalable/apps/io.wallp.App.svg
rm ~/.local/share/applications/io.wallp.App.desktop
```

## Memória

Medido nesta máquina:

| modo | RSS |
|---|---|
| `wallp --rotate` (daemon, sem Gtk) | **35 MB** |
| janela GTK4, grade carregada | 233 MB |

O GTK4 via PyGObject custa ~200 MB no `import` sozinho, antes de qualquer
widget — nenhuma otimização aqui muda isso. Por isso o daemon do systemd **não
carrega o Gtk**: ele usa só o GLib e fica nos 35 MB. Na janela, o app força
`GSK_RENDERER=cairo` (economiza ~18 MB, o padrão cai em llvmpipe sem DRI3).

## Dependências

`python3` + `pygobject` (já vem com o GNOME) + `systemd --user` para o boot.
Nada mais: sem `requests`, sem `PIL`, sem `node`.
