#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
# Security & Hardening Kit — CIS-style audit tool
# ─────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_FILE="${PROJECT_ROOT}/config/settings.yaml"

VERSION="0.1.0"
JSON_OUTPUT=false
DRY_RUN=false
RESULTS=()
OVERALL_STATUS=0

usage() {
  cat <<USAGE
Usage: $(basename "$0") [OPTIONS]

Options:
  --json         Output results as structured JSON
  --dry-run      Show what would be checked without making changes
  --version      Print version and exit
  -h, --help     Show this help message

USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUTPUT=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --version) echo "security-audit.sh v${VERSION}"; exit 0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "ERROR: Config file not found at $CONFIG_FILE" >&2
  exit 1
fi

SSH_CHECK_ROOT_LOGIN=$(yq '.ssh.check_root_login' "$CONFIG_FILE")
SSH_CHECK_PASSWORD_AUTH=$(yq '.ssh.check_password_auth' "$CONFIG_FILE")
FIREWALL_BACKEND=$(yq '.firewall.backend' "$CONFIG_FILE")
FAIL2BAN_CHECK_ENABLED=$(yq '.fail2ban.check_enabled' "$CONFIG_FILE")

if [[ "$JSON_OUTPUT" != "true" ]]; then
  echo "Security & Hardening Kit v${VERSION}"
  echo "Project root: ${PROJECT_ROOT}"
  echo "Dry run: ${DRY_RUN}"
  echo "JSON output: ${JSON_OUTPUT}"
fi

# ─────────────────────────────────────────────
# Check: SSH root login
# ─────────────────────────────────────────────
check_ssh_root_login() {
  local sshd_config="/etc/ssh/sshd_config"
  local result="PASS"
  local detail=""

  if [[ "$SSH_CHECK_ROOT_LOGIN" != "true" ]]; then
    echo "SKIP: ssh_root_login (disabled in config)"
    return
  fi

  if [[ ! -f "$sshd_config" ]]; then
    result="FAIL"
    detail="sshd_config not found at $sshd_config"
  elif grep -qE '^\s*PermitRootLogin\s+(yes)\s*$' "$sshd_config"; then
    result="FAIL"
    detail="PermitRootLogin is set to yes"
  else
    detail="PermitRootLogin is not set to yes"
  fi

  RESULTS+=("{\"check\":\"ssh_root_login\",\"result\":\"${result}\",\"detail\":\"${detail}\"}")
  [[ "$result" == "FAIL" ]] && OVERALL_STATUS=1

  if [[ "$JSON_OUTPUT" != "true" ]]; then
    echo "[$result] SSH root login check — $detail"
  fi
}

# ─────────────────────────────────────────────
# Check: Firewall active
# ─────────────────────────────────────────────
check_firewall_active() {
  local result="PASS"
  local detail=""

  case "$FIREWALL_BACKEND" in
    ufw)
      if ! command -v ufw &>/dev/null; then
        result="FAIL"
        detail="ufw command not found"
      elif ufw status 2>/dev/null | grep -q "Status: active"; then
        detail="ufw is active"
      else
        result="FAIL"
        detail="ufw is installed but not active"
      fi
      ;;
    firewalld)
      if ! command -v firewall-cmd &>/dev/null; then
        result="FAIL"
        detail="firewall-cmd not found"
      elif firewall-cmd --state 2>/dev/null | grep -q "running"; then
        detail="firewalld is running"
      else
        result="FAIL"
        detail="firewalld is installed but not running"
      fi
      ;;
    nftables)
      if ! command -v nft &>/dev/null; then
        result="FAIL"
        detail="nft command not found"
      elif [[ -n "$(nft list ruleset 2>/dev/null)" ]]; then
        detail="nftables has active rules"
      else
        result="FAIL"
        detail="nftables has no active rules"
      fi
      ;;
    *)
      result="FAIL"
      detail="unknown firewall backend: $FIREWALL_BACKEND"
      ;;
  esac

  RESULTS+=("{\"check\":\"firewall_active\",\"result\":\"${result}\",\"detail\":\"${detail}\"}")
  [[ "$result" == "FAIL" ]] && OVERALL_STATUS=1

  if [[ "$JSON_OUTPUT" != "true" ]]; then
    echo "[$result] Firewall active check — $detail"
  fi
}

# ─────────────────────────────────────────────
# Check: fail2ban active
# ─────────────────────────────────────────────
check_fail2ban_active() {
  local result="PASS"
  local detail=""

  if [[ "$FAIL2BAN_CHECK_ENABLED" != "true" ]]; then
    echo "SKIP: fail2ban_active (disabled in config)"
    return
  fi

  if ! command -v fail2ban-client &>/dev/null; then
    result="FAIL"
    detail="fail2ban-client not found"
  elif systemctl is-active --quiet fail2ban 2>/dev/null; then
    detail="fail2ban service is active"
  else
    result="FAIL"
    detail="fail2ban is installed but not active"
  fi

  RESULTS+=("{\"check\":\"fail2ban_active\",\"result\":\"${result}\",\"detail\":\"${detail}\"}")
  [[ "$result" == "FAIL" ]] && OVERALL_STATUS=1

  if [[ "$JSON_OUTPUT" != "true" ]]; then
    echo "[$result] fail2ban active check — $detail"
  fi
}

check_ssh_root_login
check_firewall_active
check_fail2ban_active

if [[ "$JSON_OUTPUT" == "true" ]]; then
  printf '[%s]\n' "$(IFS=,; echo "${RESULTS[*]}")"
fi

exit "$OVERALL_STATUS"
