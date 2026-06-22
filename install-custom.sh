#!/usr/bin/env bash
#
# install-custom.sh — Custom installer for solana-agent-ops-skill
#
# Full control over install location, CLAUDE.md placement, and which
# components (skill / agents / commands / rules) get installed.
#
# Usage:
#   ./install-custom.sh
#
set -euo pipefail

SKILL_NAME="solana-agent-ops"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

ask() {
  # ask "Prompt" "default" -> echoes answer
  local prompt="$1" default="$2" reply
  read -r -p "$prompt [$default] " reply
  printf "%s" "${reply:-$default}"
}

confirm() {
  local prompt="$1" reply
  read -r -p "$prompt [Y/n] " reply
  case "$reply" in ""|y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

# Copy a component directory file-by-file. Same-named files from other
# skills are backed up before overwrite because shared dirs like
# ~/.claude/agents/ are common ground across every skill.
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
# what we're about to write. CLAUDE.md is a single shared file, not a
# namespaced one, so silent loss here is the costliest mistake an
# installer can make.
backup_if_changing() {
  local target="$1" new_content="$2"
  if [ -f "$target" ] && ! cmp -s "$target" "$new_content"; then
    local backup
    backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
    cp "$target" "$backup"
    warn "Existing $(basename "$target") differs — backed up to $backup before overwriting"
  fi
}

printf "\n%s\n" "${BOLD}Solana Agent Ops Skill — custom installer${RESET}"
printf "%s\n\n" "${DIM}Pick where things go and what gets installed.${RESET}"

if [ ! -d "$SCRIPT_DIR/skill" ]; then
  err "Could not find ./skill next to this script. Run from the repo root."
  exit 1
fi

# ---------------------------------------------------------------------------
# 1. Where should the skill live?
# ---------------------------------------------------------------------------
printf "%s\n" "${BOLD}1) Install location${RESET}"
printf "   %s\n" "[1] Personal   ~/.claude/skills/        (available in every project)"
printf "   %s\n" "[2] Project     ./.claude/skills/        (committed with this repo)"
printf "   %s\n" "[3] Custom      (you type the path)"
choice="$(ask "Choose 1/2/3" "1")"
case "$choice" in
  1) BASE="$HOME/.claude" ;;
  2) BASE="$(pwd)/.claude" ;;
  3) BASE="$(ask "Enter base .claude directory" "$HOME/.claude")" ;;
  *) err "Invalid choice"; exit 1 ;;
esac
SKILLS_DIR="$BASE/skills"
DEST="$SKILLS_DIR/$SKILL_NAME"
printf "\n"

# ---------------------------------------------------------------------------
# 2. Which components?
# ---------------------------------------------------------------------------
printf "%s\n" "${BOLD}2) Components${RESET}"
INSTALL_SKILL=1
INSTALL_AGENTS=1
INSTALL_COMMANDS=1
INSTALL_RULES=1
confirm "Install the ops skill knowledge (skill/)?"     || INSTALL_SKILL=0
confirm "Install specialized agents (agents/)?"          || INSTALL_AGENTS=0
confirm "Install workflow commands (commands/)?"         || INSTALL_COMMANDS=0
confirm "Install always-on rules (rules/)?"              || INSTALL_RULES=0
printf "\n"

# ---------------------------------------------------------------------------
# 3. CLAUDE.md placement
# ---------------------------------------------------------------------------
printf "%s\n" "${BOLD}3) CLAUDE.md${RESET}"
CLAUDE_MD_DEST=""
if confirm "Install CLAUDE.md?"; then
  CLAUDE_MD_DEST="$(ask "Where should CLAUDE.md go?" "$BASE/CLAUDE.md")"
fi
printf "\n"

# ---------------------------------------------------------------------------
# Summary + confirm
# ---------------------------------------------------------------------------
printf "%s\n" "${BOLD}Summary${RESET}"
printf "   skill     : %s\n" "$([ "$INSTALL_SKILL" = 1 ] && echo "$DEST" || echo "skip")"
printf "   agents    : %s\n" "$([ "$INSTALL_AGENTS" = 1 ] && echo "$BASE/agents" || echo "skip")"
printf "   commands  : %s\n" "$([ "$INSTALL_COMMANDS" = 1 ] && echo "$BASE/commands" || echo "skip")"
printf "   rules     : %s\n" "$([ "$INSTALL_RULES" = 1 ] && echo "$BASE/rules" || echo "skip")"
printf "   CLAUDE.md : %s\n\n" "${CLAUDE_MD_DEST:-skip}"
confirm "Proceed?" || { warn "Aborted."; exit 0; }

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------
if [ "$INSTALL_SKILL" = 1 ]; then
  if [ -d "$DEST" ]; then
    warn "Existing skill at $DEST"
    if confirm "Overwrite?"; then
      rm -rf "$DEST"
    else
      err "Aborting."
      exit 1
    fi
  fi
  mkdir -p "$DEST"
  cp -R "$SCRIPT_DIR/skill/." "$DEST/"
  ok "Skill → $DEST"
fi

for pair in "agents:$INSTALL_AGENTS" "commands:$INSTALL_COMMANDS" "rules:$INSTALL_RULES"; do
  component="${pair%%:*}"; flag="${pair##*:}"
  if [ "$flag" = 1 ] && [ -d "$SCRIPT_DIR/$component" ]; then
    copy_component_safely "$SCRIPT_DIR/$component" "$BASE/$component" "$component"
    ok "$component → $BASE/$component"
  fi
done

if [ -n "$CLAUDE_MD_DEST" ] && [ -f "$SCRIPT_DIR/CLAUDE.md" ]; then
  mkdir -p "$(dirname "$CLAUDE_MD_DEST")"
  if [ -f "$CLAUDE_MD_DEST" ]; then
    warn "$CLAUDE_MD_DEST exists."
    if confirm "Overwrite (a backup will be saved first)?"; then
      backup_if_changing "$CLAUDE_MD_DEST" "$SCRIPT_DIR/CLAUDE.md"
      cp "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_MD_DEST"
      ok "CLAUDE.md → $CLAUDE_MD_DEST"
    else
      warn "Kept existing CLAUDE.md — merge ./CLAUDE.md manually."
    fi
  else
    cp "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_MD_DEST"
    ok "CLAUDE.md → $CLAUDE_MD_DEST"
  fi
fi

printf "\n%s\n" "${GREEN}${BOLD}Done.${RESET}"
printf "%s\n\n" "Open Claude Code and ask it to set up your agent's Squads identity."
