#!/usr/bin/env sh
set -eu

src_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
name="autonomous-work-loops"
mode="copy"

if [ "${1:-}" = "--symlink" ]; then
  mode="symlink"
fi

for root in "$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.agents/skills"; do
  mkdir -p "$root"
  dest="$root/$name"
  rm -rf "$dest"
  if [ "$mode" = "symlink" ]; then
    ln -s "$src_dir" "$dest"
  else
    mkdir -p "$dest"
    cp -R "$src_dir"/. "$dest"/
  fi
  printf '%s\n' "installed $dest"
done
