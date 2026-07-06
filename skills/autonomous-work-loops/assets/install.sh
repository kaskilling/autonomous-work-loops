#!/usr/bin/env sh
set -eu

src_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
name="autonomous-work-loops"
mode="copy"
force=0

usage() {
  printf '%s\n' "usage: $0 [--symlink] [--force]" >&2
  exit 2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --symlink)
      mode="symlink"
      ;;
    --force)
      force=1
      ;;
    -h|--help)
      printf '%s\n' "usage: $0 [--symlink] [--force]"
      printf '%s\n' ""
      printf '%s\n' "By default, existing installs are moved aside to a timestamped backup."
      printf '%s\n' "Use --force to replace an existing install without creating a backup."
      exit 0
      ;;
    *)
      usage
      ;;
  esac
  shift
done

timestamp="$(date +%Y%m%d%H%M%S)"

prepare_dest() {
  dest="$1"

  if [ -L "$dest" ]; then
    target="$(readlink "$dest")"
    if [ "$mode" = "symlink" ] && [ "$target" = "$src_dir" ]; then
      printf '%s\n' "already installed $dest"
      return 1
    fi
  elif [ ! -e "$dest" ]; then
    return 0
  fi

  if [ "$force" -eq 1 ]; then
    rm -rf "$dest"
    printf '%s\n' "replaced existing $dest"
    return 0
  fi

  backup="${dest}.backup.${timestamp}"
  suffix=1
  while [ -e "$backup" ] || [ -L "$backup" ]; do
    backup="${dest}.backup.${timestamp}.${suffix}"
    suffix=$((suffix + 1))
  done

  mv "$dest" "$backup"
  printf '%s\n' "backed up existing $dest to $backup"
  return 0
}

for root in "$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.agents/skills"; do
  mkdir -p "$root"
  dest="$root/$name"
  if ! prepare_dest "$dest"; then
    continue
  fi

  if [ "$mode" = "symlink" ]; then
    ln -s "$src_dir" "$dest"
  else
    mkdir -p "$dest"
    cp -R "$src_dir"/. "$dest"/
  fi
  printf '%s\n' "installed $dest"
done

printf '%s\n' "next: in each target repo, install/authenticate GitHub CLI with: gh auth login && gh auth status"
