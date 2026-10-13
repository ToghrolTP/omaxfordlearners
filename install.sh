#!/usr/bin/env bash
# ==============================================================================
#  omaxfordlearners - Rich Installation Script for Omarchy
#  Installs Oxford Learner's Dictionary plugin, desktop launcher, and icon
# ==============================================================================

set -euo pipefail

PLUGIN_ID="toghroltp.omaxfordlearners"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMARCHY_PLUGINS_DIR="${HOME}/.config/omarchy/plugins"
TARGET_DIR="${OMARCHY_PLUGINS_DIR}/${PLUGIN_ID}"
BIN_DIR="${HOME}/.local/bin"
DESKTOP_DIR="${HOME}/.local/share/applications"
ICON_DIR="${HOME}/.local/share/icons/hicolor/scalable/apps"
PIXMAP_DIR="${HOME}/.local/share/pixmaps"

# Colors & Formatting
BOLD="\033[1m"
DIM="\033[2m"
CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

log_step() { echo -e " ${CYAN}==>${RESET} ${BOLD}$*${RESET}"; }
log_ok()   { echo -e "   ${GREEN}✓${RESET} $*"; }
log_info() { echo -e "   ${CYAN}i${RESET} ${DIM}$*${RESET}"; }
log_warn() { echo -e "   ${YELLOW}!${RESET} ${YELLOW}$*${RESET}"; }
log_err()  { echo -e "   ${RED}✗${RESET} ${RED}$*${RESET}" >&2; }

print_banner() {
  echo -e "${BOLD}${CYAN}"
  echo " ┌─────────────────────────────────────────────────────────────┐"
  echo " │        Oxford Learner's Dictionary for Omarchy             │"
  echo " │              Installation & Setup Wizard                    │"
  echo " └─────────────────────────────────────────────────────────────┘"
  echo -e "${RESET}"
}

show_help() {
  cat <<HELP
Usage: ./install.sh [options]

Install omaxfordlearners into Omarchy with full desktop launcher integration.

Options:
  --copy          Copy plugin directory instead of symlinking (default: symlink)
  --no-bar        Install desktop launcher & overlay only without enabling on bar
  --uninstall     Completely remove omaxfordlearners, desktop entry, and icons
  -h, --help      Display this help message

HELP
}

check_prerequisites() {
  log_step "Checking system prerequisites..."

  local missing=()
  for cmd in python3 quickshell omarchy omarchy-plugin-validate; do
    if ! command -v "$cmd" &>/dev/null; then
      missing+=("$cmd")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    log_err "Missing required dependencies: ${missing[*]}"
    echo -e "   Please ensure Omarchy and Quickshell are properly installed."
    exit 1
  fi
  log_ok "Required dependencies found (python3, quickshell, omarchy)"

  if ! command -v mpv &>/dev/null; then
    log_warn "mpv is not installed. Native pronunciation audio playback requires mpv."
    log_info "Install with: sudo pacman -S mpv"
  else
    log_ok "Audio playback backend found (mpv)"
  fi
}

validate_plugin() {
  log_step "Validating plugin manifest and schema..."
  if ! omarchy-plugin-validate "$PROJECT_DIR"; then
    log_err "Plugin manifest validation failed."
    exit 1
  fi
  log_ok "Plugin manifest is valid (schemaVersion: 1, kinds: overlay, bar-widget)"
}

install_plugin() {
  local install_mode="${1:-link}"
  mkdir -p "$OMARCHY_PLUGINS_DIR"

  log_step "Installing Omarchy plugin to $TARGET_DIR..."

  if [ -e "$TARGET_DIR" ] || [ -L "$TARGET_DIR" ]; then
    log_info "Removing existing installation at $TARGET_DIR"
    rm -rf "$TARGET_DIR"
  fi

  if [ "$install_mode" = "copy" ]; then
    cp -r "$PROJECT_DIR" "$TARGET_DIR"
    log_ok "Plugin copied to $TARGET_DIR"
  else
    ln -s "$PROJECT_DIR" "$TARGET_DIR"
    log_ok "Plugin symlinked to $TARGET_DIR"
  fi

  # Rescan running shell plugins
  if command -v omarchy-shell &>/dev/null; then
    omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
    log_ok "Notified running Omarchy shell to rescan plugins"
  fi
}

enable_bar_widget() {
  log_step "Enabling bar widget in Omarchy..."
  if omarchy plugin enable "$PLUGIN_ID" right 2>/dev/null; then
    log_ok "Added Oxford Dictionary widget to the right bar section"
  else
    log_warn "Could not automatically position on bar (may already be placed)"
  fi
}

install_desktop_integration() {
  log_step "Installing desktop launcher and icon integration..."

  # 1. Launcher binary
  mkdir -p "$BIN_DIR"
  cp "$PROJECT_DIR/bin/omaxfordlearners" "$BIN_DIR/omaxfordlearners"
  chmod +x "$BIN_DIR/omaxfordlearners"
  log_ok "Installed launcher command: $BIN_DIR/omaxfordlearners"

  if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    log_warn "$BIN_DIR is not in your current PATH. Add it to ~/.bashrc or ~/.zshrc:"
    log_info "export PATH=\"\$HOME/.local/bin:\$PATH\""
  fi

  # 2. Application icon
  mkdir -p "$ICON_DIR" "$PIXMAP_DIR"
  if [ -f "$PROJECT_DIR/assets/omaxfordlearners.svg" ]; then
    cp "$PROJECT_DIR/assets/omaxfordlearners.svg" "$ICON_DIR/omaxfordlearners.svg"
    cp "$PROJECT_DIR/assets/omaxfordlearners.svg" "$PIXMAP_DIR/omaxfordlearners.svg"
    log_ok "Installed scalable icon to $ICON_DIR and $PIXMAP_DIR"
  fi

  # 3. Desktop Entry (.desktop file)
  mkdir -p "$DESKTOP_DIR"
  if [ -f "$PROJECT_DIR/assets/omaxfordlearners.desktop" ]; then
    cp "$PROJECT_DIR/assets/omaxfordlearners.desktop" "$DESKTOP_DIR/omaxfordlearners.desktop"
    chmod +x "$DESKTOP_DIR/omaxfordlearners.desktop"
    log_ok "Installed desktop entry: $DESKTOP_DIR/omaxfordlearners.desktop"
  fi

  # 4. Update system desktop database
  if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
    log_ok "Updated desktop application database"
  fi

  if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f -t "${HOME}/.local/share/icons/hicolor" 2>/dev/null || true
  fi
}

uninstall() {
  log_step "Uninstalling omaxfordlearners..."

  # Disable in bar
  if command -v omarchy &>/dev/null; then
    omarchy plugin disable "$PLUGIN_ID" 2>/dev/null || true
    log_ok "Disabled plugin in Omarchy bar"
  fi

  # Remove plugin files
  if [ -e "$TARGET_DIR" ] || [ -L "$TARGET_DIR" ]; then
    rm -rf "$TARGET_DIR"
    log_ok "Removed $TARGET_DIR"
  fi

  # Remove launcher and desktop files
  rm -f "$BIN_DIR/omaxfordlearners"
  rm -f "$DESKTOP_DIR/omaxfordlearners.desktop"
  rm -f "$ICON_DIR/omaxfordlearners.svg"
  rm -f "$PIXMAP_DIR/omaxfordlearners.svg"
  log_ok "Removed launcher binary, desktop entry, and icon"

  if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
  fi

  echo -e "\n${GREEN}${BOLD}✓ Uninstallation complete!${RESET}\n"
}

main() {
  local mode="link"
  local enable_bar=true

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --copy)
        mode="copy"
        shift
        ;;
      --no-bar)
        enable_bar=false
        shift
        ;;
      --uninstall)
        print_banner
        uninstall
        exit 0
        ;;
      -h|--help)
        show_help
        exit 0
        ;;
      *)
        log_err "Unknown option: $1"
        show_help
        exit 1
        ;;
    esac
  done

  print_banner
  check_prerequisites
  validate_plugin
  install_plugin "$mode"

  if [ "$enable_bar" = true ]; then
    enable_bar_widget
  fi

  install_desktop_integration

  echo -e "\n${GREEN}${BOLD}✓ Installation finished successfully!${RESET}"
  echo -e "\n${BOLD}How to access Oxford Dictionary:${RESET}"
  echo -e "  • ${CYAN}App Launcher:${RESET}   Search for 'Oxford Dictionary' in your app launcher (Rofi/Walker/Fuzzel)"
  echo -e "  • ${CYAN}Omarchy Bar:${RESET}    Click the book icon (${BOLD}󰏪${RESET}) on your bar"
  echo -e "  • ${CYAN}Terminal:${RESET}       Run ${BOLD}omaxfordlearners [word]${RESET}"
  echo -e "  • ${CYAN}Hyprland Bind:${RESET}  Add to ~/.config/hypr/hyprland.conf:"
  echo -e "                 ${DIM}bind = \$mainMod, D, exec, omaxfordlearners${RESET}\n"
}

main "$@"
