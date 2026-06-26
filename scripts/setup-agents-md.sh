#!/bin/bash
set -u

CLAUDE_DIR="$HOME/.claude"
HOOK="$CLAUDE_DIR/hooks/append_agents_md.sh"
SETTINGS="$CLAUDE_DIR/settings.json"
MANIFEST="$CLAUDE_DIR/agents_md_links.txt"
GITIGNORE="${XDG_CONFIG_HOME:-$HOME/.config}/git/ignore"
GI_ENTRIES=("CLAUDE.md" ".compiled-claude.md")

write_hook() {
  mkdir -p "$(dirname "$HOOK")"
  cat > "$HOOK" <<'HOOK_EOF'
#!/bin/bash
root="${CLAUDE_PROJECT_DIR:-$PWD}"
manifest="$HOME/.claude/agents_md_links.txt"

record() {
  [ -f "$manifest" ] && grep -qxF "$1" "$manifest" 2>/dev/null && return
  mkdir -p "$(dirname "$manifest")"
  echo "$1" >> "$manifest"
}

compile_dir() {
  local dir="$1"
  local out="$dir/.compiled-claude.md"
  local f files
  [ -w "$dir" ] || return 1
  files="$(find "$dir" -maxdepth 1 -iname '*agents.md' -type f 2>/dev/null | sort)"
  [ -n "$files" ] || return 1
  : > "$out"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    printf '# %s\n\n' "$f" >> "$out"
    cat "$f" >> "$out"
    printf '\n' >> "$out"
  done <<< "$files"
  record "$out"
  return 0
}

link_claude() {
  local link="$1" target="$2"
  if [ -L "$link" ]; then
    ln -sfn "$target" "$link"
    record "$link"
  elif [ ! -e "$link" ]; then
    ln -s "$target" "$link"
    record "$link"
  fi
}

cleanup_dir() {
  local link="$1" target="$2" out="$3"
  if [ -L "$link" ] && [ "$(readlink "$link")" = "$target" ]; then
    rm -f "$link"
  fi
  [ -f "$out" ] && rm -f "$out"
}

process_dir() {
  local dir="$1"
  [ -d "$dir" ] || return
  [ "$dir" = "$HOME" ] && return
  if compile_dir "$dir"; then
    link_claude "$dir/CLAUDE.md" ".compiled-claude.md"
  else
    cleanup_dir "$dir/CLAUDE.md" ".compiled-claude.md" "$dir/.compiled-claude.md"
  fi
}

if compile_dir "$HOME"; then
  link_claude "$HOME/.claude/CLAUDE.md" "$HOME/.compiled-claude.md"
else
  cleanup_dir "$HOME/.claude/CLAUDE.md" "$HOME/.compiled-claude.md" "$HOME/.compiled-claude.md"
fi

dir="$root"
while :; do
  process_dir "$dir"
  [ "$dir" = "/" ] && break
  dir="$(dirname "$dir")"
done
HOOK_EOF
  echo "wrote hook: $HOOK"
}

add_settings_hook() {
  python3 - "$SETTINGS" "$HOOK" <<'PY'
import json, os, sys
path, hook = sys.argv[1], sys.argv[2]
try:
    with open(path) as f:
        data = json.load(f)
except FileNotFoundError:
    data = {}
cmd = f"bash {hook}"
ss = data.setdefault("hooks", {}).setdefault("SessionStart", [])
if any(h.get("command") == cmd for e in ss for h in e.get("hooks", [])):
    print("settings: SessionStart hook already present")
else:
    ss.append({"matcher": "startup|resume",
               "hooks": [{"type": "command", "command": cmd}]})
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    print("settings: added SessionStart hook")
PY
}

add_gitignore() {
  mkdir -p "$(dirname "$GITIGNORE")"
  local e
  for e in "${GI_ENTRIES[@]}"; do
    if grep -qxF "$e" "$GITIGNORE" 2>/dev/null; then
      echo "gitignore: $e already present"
    else
      echo "$e" >> "$GITIGNORE"
      echo "gitignore: added $e to $GITIGNORE"
    fi
  done
}

remove_settings_hook() {
  [ -f "$SETTINGS" ] || return 0
  python3 - "$SETTINGS" "$HOOK" <<'PY'
import json, sys
path, hook = sys.argv[1], sys.argv[2]
with open(path) as f:
    data = json.load(f)
cmd = f"bash {hook}"
hooks = data.get("hooks", {})
ss = hooks.get("SessionStart")
if not ss:
    sys.exit(0)
kept = [e for e in ss if not any(h.get("command") == cmd for h in e.get("hooks", []))]
if kept:
    hooks["SessionStart"] = kept
else:
    hooks.pop("SessionStart", None)
if not hooks:
    data.pop("hooks", None)
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print("settings: removed SessionStart hook")
PY
}

remove_artifacts() {
  [ -f "$MANIFEST" ] || return 0
  local p
  while IFS= read -r p; do
    if [ -L "$p" ]; then
      rm -f "$p"
      echo "removed symlink: $p"
    elif [ -f "$p" ] && [ "$(basename "$p")" = ".compiled-claude.md" ]; then
      rm -f "$p"
      echo "removed compiled: $p"
    fi
  done < "$MANIFEST"
  rm -f "$MANIFEST"
}

remove_gitignore() {
  [ -f "$GITIGNORE" ] || return 0
  local e tmp="$GITIGNORE.tmp.$$"
  for e in "${GI_ENTRIES[@]}"; do
    if grep -qxF "$e" "$GITIGNORE" 2>/dev/null; then
      grep -vxF "$e" "$GITIGNORE" > "$tmp" 2>/dev/null || true
      mv "$tmp" "$GITIGNORE"
      echo "gitignore: removed $e"
    fi
  done
  [ -s "$GITIGNORE" ] || rm -f "$GITIGNORE"
}

install() {
  write_hook
  add_settings_hook
  add_gitignore
  bash "$HOOK"
  echo "Installed."
}

uninstall() {
  remove_settings_hook
  remove_artifacts
  remove_gitignore
  rm -f "$HOOK"
  echo "Uninstalled."
}

case "${1:-}" in
  --uninstall) uninstall ;;
  "") install ;;
  *) echo "usage: $(basename "$0") [--uninstall]" >&2; exit 1 ;;
esac
