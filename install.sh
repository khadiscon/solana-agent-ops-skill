#!/usr/bin/env bash
#
# install.sh — Standard installer for solana-agent-ops-skill
#
# Installs the ops skill, agents, commands, and rules into your personal
# Claude Code skills directory with sensible defaults.
#
# Usage:
#   ./install.sh        Interactive with defaults (press Enter to accept)
#   ./install.sh -y     Non-interactive, accept all defaults
#
# For full control (location, component selection), use ./install-custom.sh
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
SKILL_NAME="solana-agent-ops"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
SKILLS_DIR="$CLAUDE_HOME/skills"
DEST="$SKILLS_DIR/$SKILL_NAME"
ASSUME_YES=0

# ---------------------------------------------------------------------------
# Pretty output
# ---------------------------------------------------------------------------
if [ -t 1 ]; then
  BOLD="$(printf '\033[1m')"; DIM="$(printf '\033[2m')"; RESET="$(printf '\033[0m')"
  GREEN="$(printf '\033[32m')"; YELLOW="$(printf '\033[33m')"; RED="$(printf '\033[31m')"; BLUE="$(printf '\033[34m')"
else
  BOLD=""; DIM=""; RESET=""; GREEN=""; YELLOW=""; RED=""; BLUE=""
fi
info()  { printf "%s\n" "${BLUE}•${RESET} $*"; }
ok()    { printf "%s\n" "${GREEN}✓${RESET} $*"; }
warn()  { printf "%s\n" "${YELLOW}!${RESET} $*"; }
err()   { printf "%s\n" "${RED}✗${RESET} $*" >&2; }

# ---------------------------------------------------------------------------
# Args
# ---------------------------------------------------------------------------
for arg in "$@"; do
  case "$arg" in
    -y|--yes) ASSUME_YES=1 ;;
    -h|--help)
      # Print only the leading usage docstring (lines 2..N up to the first
      # blank, non-comment line), not every '#' section divider in the body.
      sed -n '2,/^[^#]/p' "$0" | sed '$d' | sed 's/^#\s\?//'
      exit 0 ;;
    *) err "Unknown option: $arg"; exit 1 ;;
  esac
done

confirm() {
  # confirm "Question?"  -> returns 0 for yes
  local prompt="$1"
  if [ "$ASSUME_YES" -eq 1 ]; then return 0; fi
  read -r -p "$prompt [Y/n] " reply
  case "$reply" in
    ""|y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

# Copy a component directory file-by-file into a shared Claude config dir.
# Same-named files from other skills are backed up before overwrite because
# shared dirs like ~/.claude/agents/ are common ground across every skill.
copy_component_safely() {
  local src_dir="$1" dest_dir="$2" label="$3"
  local f rel backup collisions=0
  mkdir -p "$dest_dir"
  while IFS= read -r -d '' f; do
    rel="${f#"$src_dir"/}"
    if [ -f "$dest_dir/$rel" ] && ! cmp -s "$f" "$dest_dir/$rel"; then
      backup="$dest_dir/$rel.bak.$(date +%Y%m%d%H%M%S)"
      cp "$dest_dir/$rel" "$backup"
      warn "$label/$rel differs at $dest_dir/$rel — backed up to $backup before overwriting"
      collisions=$((collisions + 1))
    fi
    mkdir -p "$dest_dir/$(dirname "$rel")"
    cp "$f" "$dest_dir/$rel"
  done < <(find "$src_dir" -type f -print0)
  if [ "$collisions" -gt 0 ]; then
    warn "$collisions file(s) in $label/ were overwritten after backup"
  fi
}

# Back up a file before it gets overwritten, but only if it differs from
# what we're about to write (so re-running the installer doesn't pile up
# junk backups). Always runs — even under -y — because CLAUDE.md is a
# single shared file, not a namespaced one, so silent loss here is the
# costliest mistake this installer can make.
backup_if_changing() {
  local target="$1" new_content="$2"
  if [ -f "$target" ] && ! cmp -s "$target" "$new_content"; then
    local backup
    backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
    cp "$target" "$backup"
    warn "Existing $(basename "$target") differs — backed up to $backup before overwriting"
  fi
}

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------
printf "\n%s\n" "${BOLD}Solana Agent Ops Skill — standard installer${RESET}"
printf "%s\n\n" "${DIM}Installs skill + agents + commands + rules into $SKILLS_DIR${RESET}"

if [ ! -d "$SCRIPT_DIR/skill" ]; then
  err "Could not find ./skill next to this script. Run from the repo root."
  exit 1
fi

mkdir -p "$SKILLS_DIR"

# ---------------------------------------------------------------------------
# Existing install?
# ---------------------------------------------------------------------------
if [ -d "$DEST" ]; then
  warn "An existing install was found at $DEST"
  if confirm "Overwrite it?"; then
    rm -rf "$DEST"
  else
    err "Aborting to avoid clobbering your install. Use ./install-custom.sh for more options."
    exit 1
  fi
fi

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------
info "Installing skill files → $DEST"
mkdir -p "$DEST"
cp -R "$SCRIPT_DIR/skill/." "$DEST/"
ok "Skill installed"

for component in agents commands rules; do
  if [ -d "$SCRIPT_DIR/$component" ]; then
    info "Installing $component → $CLAUDE_HOME/$component"
    copy_component_safely "$SCRIPT_DIR/$component" "$CLAUDE_HOME/$component" "$component"
    ok "$component installed"
  fi
done

if [ -f "$SCRIPT_DIR/CLAUDE.md" ]; then
  if [ -f "$CLAUDE_HOME/CLAUDE.md" ]; then
    if [ "$ASSUME_YES" -eq 0 ]; then
      warn "$CLAUDE_HOME/CLAUDE.md already exists."
      if ! confirm "Overwrite it (a backup will be saved first)?"; then
        warn "Kept your existing CLAUDE.md. Review ./CLAUDE.md and merge manually."
        CLAUDE_MD_SKIPPED=1
      fi
    fi
    if [ "${CLAUDE_MD_SKIPPED:-0}" -eq 0 ]; then
      backup_if_changing "$CLAUDE_HOME/CLAUDE.md" "$SCRIPT_DIR/CLAUDE.md"
      cp "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md"
      ok "CLAUDE.md updated"
    fi
  else
    cp "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md"
    ok "CLAUDE.md installed"
  fi
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
printf "\n%s\n" "${GREEN}${BOLD}Done.${RESET}"
printf "%s\n" "Skill:    $DEST"
printf "%s\n" "Config:   $CLAUDE_HOME/CLAUDE.md"
printf "\n%s\n" "Open Claude Code and try:"
printf "%s\n\n" "  ${DIM}\"Set up a Squads v4 smart account as my agent's identity\"${RESET}"
