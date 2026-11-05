#!/usr/bin/env bash
# Remove o ai-usage. Contas e credenciais em ~/.local/share/agents e o cache em
# ~/.local/state/agents ficam, para não apagar logins sem querer.
set -euo pipefail

UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
systemctl --user disable --now agents-usage.timer 2>/dev/null || true
rm -f "$UNIT_DIR/agents-usage.service" "$UNIT_DIR/agents-usage.timer"
systemctl --user daemon-reload
command -v uv >/dev/null && uv tool uninstall ai-usage 2>/dev/null || true
SHIMS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/agents/shims"
rm -f "$SHIMS_DIR/agent-shim" "$SHIMS_DIR/claude" "$SHIMS_DIR/codex"
rmdir "$SHIMS_DIR" 2>/dev/null || true
echo "ai-usage removido. Dados mantidos em ${XDG_DATA_HOME:-$HOME/.local/share}/agents e ${XDG_STATE_HOME:-$HOME/.local/state}/agents"
