#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────
# Stash — Obsidian Vault Setup Script
# Installs required Obsidian community plugins
# and scaffolds the vault directory structure.
# ──────────────────────────────────────────────

# Usage:
#   ./setup.sh /path/to/vault           # interactive
#   ./setup.sh /path/to/vault --all     # install all plugins
#   ./setup.sh --list                   # show available plugins

PLUGINS=(
  "dataview|blacksmithgu/obsidian-dataview|Browse wiki articles like a database (Stash works without it)|0"
  "obsidian-git|Vinzent03/obsidian-git|Auto-backup vault to git|0"
  "tag-wrangler|pjeby/tag-wrangler|Rename and merge tags across the wiki|0"
  "obsidian-local-images-plus|Sergei-Korneev/obsidian-local-images-plus|Download remote images locally|0"
)

list_plugins() {
  echo ""
  echo "Available plugins:"
  echo ""
  local i=1
  for entry in "${PLUGINS[@]}"; do
    IFS='|' read -r id repo desc req <<< "$entry"
    if [ "$req" = "1" ]; then
      printf "  %d. [required]    %-40s %s\n" "$i" "$id" "$desc"
    else
      printf "  %d. [optional]    %-40s %s\n" "$i" "$id" "$desc"
    fi
    ((i++))
  done
  echo ""
}

download_plugin() {
  local id="$1" repo="$2" desc="$3"
  local dest="$PLUGINS_DIR/$id"

  if [ -d "$dest" ] && [ -f "$dest/main.js" ]; then
    echo "  ✓ $id — already installed"
    return 0
  fi

  mkdir -p "$dest"
  local latest
  latest=$(curl -sL "https://api.github.com/repos/$repo/releases/latest" | grep '"tag_name"' | head -1 | sed 's/.*: "\(.*\)".*/\1/')

  if [ -z "$latest" ]; then
    echo "  ✗ $id — could not fetch latest release"
    rm -rf "$dest"
    return 1
  fi

  local base="https://github.com/$repo/releases/download/$latest"
  local ok=true

  for file in main.js manifest.json; do
    if ! curl -sfL "$base/$file" -o "$dest/$file"; then
      echo "  ✗ $id — failed to download $file"
      ok=false
    fi
  done
  curl -sfL "$base/styles.css" -o "$dest/styles.css" 2>/dev/null || true

  if [ "$ok" = true ]; then
    echo "  ✓ $id ($latest) — $desc"
  else
    echo "  ✗ $id — installation failed"
    rm -rf "$dest"
    return 1
  fi
}

# ── Parse args ───────────────────────────────
if [ "${1:-}" = "--list" ]; then
  list_plugins
  exit 0
fi

VAULT="${1:-}"
MODE="${2:-}"

if [ -z "$VAULT" ]; then
  read -rp "Enter Obsidian vault path: " VAULT
fi
VAULT="${VAULT/#\~/$HOME}"

if [ ! -d "$VAULT" ]; then
  echo "Creating vault at $VAULT..."
  mkdir -p "$VAULT"
fi

# ── Scaffold directories ────────────────────
echo ""
echo "Stash Setup"
echo "Vault: $VAULT"
echo ""

for dir in inbox wiki output archive; do
  mkdir -p "$VAULT/$dir"
  echo "  ✓ $dir/"
done

# ── Install Obsidian plugins ─────────────────
OBSIDIAN_DIR="$VAULT/.obsidian"
PLUGINS_DIR="$OBSIDIAN_DIR/plugins"
mkdir -p "$PLUGINS_DIR"

SELECTED=()

if [ "$MODE" = "--all" ]; then
  for entry in "${PLUGINS[@]}"; do
    IFS='|' read -r id _ _ _ <<< "$entry"
    SELECTED+=("$id")
  done
else
  for entry in "${PLUGINS[@]}"; do
    IFS='|' read -r id repo desc req <<< "$entry"
    if [ "$req" = "1" ]; then
      echo "  [required] $id — $desc"
      SELECTED+=("$id")
    else
      read -rp "  [optional] $id — $desc (y/n) " answer
      if [[ "$answer" =~ ^[Yy] ]]; then
        SELECTED+=("$id")
      fi
    fi
  done
fi

echo ""
echo "Installing plugins..."
for entry in "${PLUGINS[@]}"; do
  IFS='|' read -r id repo desc req <<< "$entry"
  for sel in "${SELECTED[@]}"; do
    if [ "$sel" = "$id" ]; then
      download_plugin "$id" "$repo" "$desc"
      break
    fi
  done
done

# ── Write community-plugins.json ─────────────
json="["
first=true
for id in "${SELECTED[@]}"; do
  if [ -d "$PLUGINS_DIR/$id" ]; then
    [ "$first" = true ] && first=false || json+=","
    json+="\"$id\""
  fi
done
json+="]"
echo "$json" > "$OBSIDIAN_DIR/community-plugins.json"

echo ""
echo "Done! Restart Obsidian if it's running."
echo ""
echo "Next steps:"
echo "  1. Install Obsidian Web Clipper for your browser"
echo "  2. Import a clipper template from clipper-templates/"
echo "  3. Copy config.example.yaml to $VAULT/config.yaml and customize"
echo "  4. Start clipping! Then run: stash process"
echo ""
