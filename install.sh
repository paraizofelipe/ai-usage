#!/usr/bin/env bash
# Instala o ai-usage: CLI/painel (uv tool), shims de claude/codex e timer do systemd --user.
# Rodar de novo atualiza a instalação. Uso: ./install.sh
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

die() { echo "ai-usage: $*" >&2; exit 1; }
command -v uv >/dev/null || die "uv não encontrado (https://docs.astral.sh/uv/)"
command -v systemctl >/dev/null || die "systemd --user é necessário para o timer de coleta"
for cmd in notify-send gdbus; do
  command -v "$cmd" >/dev/null || echo "AVISO: '$cmd' ausente: os alertas de limite não vão aparecer"
done

# --force: substitui executáveis antigos com o mesmo nome em ~/.local/bin
uv tool install --quiet --force --reinstall .
BIN_DIR=$(uv tool dir --bin)

SHIMS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/agents/shims"
mkdir -p "$SHIMS_DIR"
install -m 755 shims/agent-shim "$SHIMS_DIR/agent-shim"
ln -sfn agent-shim "$SHIMS_DIR/claude"
ln -sfn agent-shim "$SHIMS_DIR/codex"

UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
mkdir -p "$UNIT_DIR"
# rm antes: a unit pode ser um symlink de instalação antiga e o sed escreveria através dele
rm -f "$UNIT_DIR/agents-usage.service" "$UNIT_DIR/agents-usage.timer"
sed "s|@BIN_DIR@|$BIN_DIR|" systemd/agents-usage.service >"$UNIT_DIR/agents-usage.service"
install -m 644 systemd/agents-usage.timer "$UNIT_DIR/agents-usage.timer"
systemctl --user daemon-reload
systemctl --user enable --now agents-usage.timer

cat <<MSG
ai-usage instalado:
  CLI e painel: $BIN_DIR/agents, $BIN_DIR/agents-panel
  shims:        $SHIMS_DIR  (coloque no início do PATH, ver README)
  timer:        agents-usage.timer
MSG
case ":$PATH:" in *":$BIN_DIR:"*) ;; *) echo "AVISO: $BIN_DIR não está no PATH" ;; esac
