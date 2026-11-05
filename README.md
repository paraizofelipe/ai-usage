# ai-usage

Mostra o uso e os limites do **Claude Code**, do **Codex** e o saldo do **OpenRouter** num ícone do
polybar. O clique abre um painel (PySide6/QML) com todas as assinaturas. Você pode ter várias contas
de Claude e Codex e trocar a conta ativa pelo painel, pela CLI ou automaticamente quando ela chega
perto do limite.

| Peça | O que faz |
|---|---|
| `agents bar` | Ícone do polybar. Só lê o cache e muda de cor conforme o ritmo de uso. Com alerta, mostra o logo do provider e o percentual |
| `agents-panel` | Painel flutuante. Um segundo clique fecha |
| `agents-usage.timer` | Coleta o uso a cada 3 min perto do limite e a cada 15 min no resto do tempo. Também dispara os alertas e a troca automática |
| Shims `claude`/`codex` | Fazem novas sessões usarem a conta ativa (`CLAUDE_CONFIG_DIR`/`CODEX_HOME`) |

## Requisitos

| Item | Por quê | Pop!_OS / Ubuntu |
|---|---|---|
| Linux com **systemd --user** | Timer de coleta | já vem |
| [**uv**](https://docs.astral.sh/uv/) | Instala o app num ambiente isolado. Ele baixa um Python ≥ 3.10 se faltar | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| **X11** + **polybar** | Ícone e posição do painel. Testado no i3 com polybar 3.5.7 | `apt install polybar` |
| Bibliotecas do plugin xcb do Qt 6 | O PySide6 vem do PyPI, mas o plugin xcb usa bibliotecas do sistema | `apt install libxcb-cursor0 libxkbcommon-x11-0 libegl1 libfontconfig1 libdbus-1-3` |
| `notify-send`, `gdbus` | Alertas de limite e o botão "Usar conta" na notificação | `apt install libnotify-bin libglib2.0-bin` |
| Servidor de notificação | Ex.: dunst ou deadd | `apt install dunst` |
| [Hack Nerd Font](https://github.com/ryanoasis/nerd-fonts/releases/tag/v3.5.1) **≥ 3.5** | Fonte do painel e logos da barra (`cod-claude` U+EC82, `cod-openai` U+EC81) | em `~/.local/share/fonts` + `fc-cache -f` |
| Font Awesome 5 Free (Solid) | Ícone de robô da barra (U+F544) | em `~/.local/share/fonts` |
| Terminal | Login de contas e `agents launch`. Padrão: `alacritty` (ver `AGENTS_TERMINAL`) | `apt install alacritty` |
| `zsh` | `agents launch` abre o agente com `zsh -ic` para herdar o PATH com os shims | `apt install zsh` |
| Chrome, Chromium, Brave ou Firefox | Login de contas extras num perfil temporário e isolado | — |
| CLIs `claude` e/ou `codex` logados | Fonte dos dados. O app usa o OAuth que os CLIs já gravaram | — |
| `OPENROUTER_API_KEY` (opcional) | Saldo do OpenRouter. Pode ficar no ambiente ou em `~/.user.env`. Sem a chave, a seção some | — |

## Instalação

```bash
git clone https://github.com/paraizofelipe/ai-usage.git ~/projects/ai-usage
cd ~/projects/ai-usage
./install.sh
```

O `install.sh` pode rodar de novo para atualizar (`git pull && ./install.sh`). Ele faz três coisas:

1. Roda `uv tool install .`, que cria `agents`, `agents-panel` e `agents-private-browser` em
   `~/.local/bin` (ou no diretório de `uv tool dir --bin`).
2. Copia os shims para `~/.local/share/agents/shims`.
3. Instala e ativa o `agents-usage.timer` no `systemd --user`.

### 1. Shims no PATH

Para que novas sessões usem a conta ativa, os shims precisam vir **antes** dos CLIs reais no PATH.
No `~/.zshrc` (ou `~/.bashrc`):

```bash
export PATH="$HOME/.local/share/agents/shims:$PATH"
```

Uma sessão com `CLAUDE_CONFIG_DIR` ou `CODEX_HOME` já definido continua usando esse valor.

### 2. Módulo do polybar

```ini
[module/agents]
type = custom/script
exec = ~/.local/bin/agents bar
interval = 20
format = <label>
label = %output%
click-left = ~/.local/bin/agents-panel &
click-right = ~/.local/bin/agents launch &
cursor-click = pointer
```

Inclua `agents` em `modules-right`. O ícone usa `%{T6}` para os logos. Então a barra precisa de uma
`font-5` com a Nerd Font, e as fontes anteriores não podem ter glifos nessa faixa (o polybar usa a
primeira fonte que tiver o glifo):

```ini
font-5 = "Hack Nerd Font:style=Regular:pixelsize=13;3"
```

### 3. Regras do i3

```
for_window [title="^agents-panel$"] floating enable, sticky enable, border none
for_window [class="agents-login"] floating enable, resize set 900 px 500 px, move position center
```

### Configuração (variáveis de ambiente)

| Variável | Padrão | Uso |
|---|---|---|
| `AGENTS_TERMINAL` | `alacritty` | Terminal do login e do `agents launch`. Precisa aceitar `--class` e `-e` |
| `AGENTS_PANEL_MONITOR` | `DP-1` | Monitor onde o painel abre (`xrandr --query`). Se não existir, usa o primário |
| `AGENTS_PANEL_TOP` | `30` | Altura da barra em px. O painel abre logo abaixo, no canto direito |
| `OPENROUTER_API_KEY` | — | Chave do OpenRouter |

## Uso

```text
agents usage-update [--if-due]           coleta agora (o timer usa --if-due)
agents usage-show                        dump do cache
agents account list [provider]
agents account add [provider] <nome>     cria a conta e abre o login numa janela privada
agents account use [provider] <conta>    troca a conta ativa (só vale para novas sessões)
agents account login [provider] <conta>
agents account rename [provider] <conta> <nome>
agents account remove [provider] <conta> [--yes]
agents account mode [provider] auto|notify [threshold]
```

- `provider` é `claude` (padrão) ou `codex`.
- `<conta>` aceita o id, o nome ou a posição (1, 2...).
- No modo `notify`, quando a conta ativa passa do threshold (95% por padrão), chega uma notificação
  com o botão "Usar <conta>". No modo `auto`, a troca é feita sozinha.

**Atalhos do painel**

| Tecla | Ação |
|---|---|
| `1`–`9` + `Enter` | Usa a conta |
| `M` | Alterna o modo (auto/avisar) |
| `R` | Atualiza |
| `Esc` | Fecha |

Clique no nome de uma conta para renomeá-la.

## Onde ficam os dados

| Caminho | Conteúdo |
|---|---|
| `~/.local/share/agents/` | Registro de contas, homes das contas extras (com credenciais) e o ponteiro da conta ativa |
| `~/.local/state/agents/` | Cache de uso (`usage.json`), alertas enviados, cache de tokens e locks |

Os diretórios são criados com permissão `0700`. As contas `main` usam `~/.claude` e `~/.codex`.

## Desinstalar

```bash
./uninstall.sh
```

Remove o app, os shims e o timer. Contas e caches ficam guardados. Para apagar tudo, remova também
`~/.local/share/agents` e `~/.local/state/agents`.

## Desenvolvimento

```bash
python3 -m unittest discover -s tests      # sem dependências: o PySide6 só é importado pelo painel
uv run agents-panel                        # painel a partir do checkout
QT_QPA_PLATFORM=offscreen uv run agents-panel --screenshot /tmp/panel.png
```

## Créditos

- Painel inspirado no *agents panel* do [Omarchy](https://github.com/basecamp/omarchy) (MIT).
- Ícones do [Simple Icons](https://simpleicons.org) (CC0). Detalhes em
  `src/agents_usage/panel/icons/README.md`. As marcas pertencem aos respectivos donos.
