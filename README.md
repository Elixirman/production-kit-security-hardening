# Security & Hardening Kit

Production Kits for Linux — Project N

![Shell](https://img.shields.io/badge/shell-bash-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Status](https://img.shields.io/badge/status-active-brightgreen)

📄 **[View full documentation](https://elixirman.github.io/production-kit-security-hardening/)**

A reusable, configurable Bash tool for auditing baseline Linux security posture — SSH hardening, firewall status, and fail2ban — designed to run unattended, in CI, or ad hoc against any server.

## Overview

Most "security audits" are one-off manual checks someone runs before a compliance deadline and forgets about. This kit is built to be dropped into any team's environment as a standing tool: configurable per-host via YAML, safe to re-run repeatedly (idempotent — it only reads state, never modifies it), and scriptable via a machine-readable `--json` mode so it can feed into monitoring or CI pipelines rather than requiring a human to read terminal output.

## Features

- SSH root login check (`PermitRootLogin`)
- Firewall active check (supports `ufw`, `firewalld`, `nftables`)
- fail2ban active check
- Dual output modes: human-readable (default) and `--json` (machine-parseable)
- Exit code reflects overall result (`0` = all checks passed, `1` = at least one failure) — CI/pipeline friendly
- Fully config-driven via YAML — no hardcoded paths or values

## Requirements

- Bash 4+
- [`yq`](https://github.com/mikefarah/yq) v4+ (YAML parsing)
- Linux (tested on Debian/Ubuntu-based distros)
- Root or sudo not required to *read* config state, but some checks (e.g. reading `/etc/ssh/sshd_config`) may need elevated permissions depending on file ownership

## Installation

```bash
git clone <your-repo-url>
cd production-kit-security-hardening
chmod +x scripts/security-audit.sh
```

## Configuration

Edit `config/settings.yaml`:

```yaml
ssh:
  check_root_login: true

firewall:
  backend: "ufw"   # options: ufw, firewalld, nftables

fail2ban:
  check_enabled: true
```

Set any check's `_check_*` or `check_enabled` flag to `false` to skip it.

## Usage

```bash
# Human-readable output
./scripts/security-audit.sh

# Machine-readable JSON, for piping into jq or a monitoring pipeline
./scripts/security-audit.sh --json | jq .

# Check the exit code in a CI step
./scripts/security-audit.sh --json > results.json || echo "Security check failed"
```

## Output

Human mode prints one `[PASS]`/`[FAIL]`/`SKIP` line per check. JSON mode prints a single JSON array:

```json
[{"check":"ssh_root_login","result":"FAIL","detail":"PermitRootLogin is set to yes"}]
```

## Testing

```bash
bats tests/security-audit.bats
```

## Known Limitations

- Firewall check currently supports one backend per run (set in config), not auto-detection across all three
- No remediation — this tool audits and reports; it does not modify system state

## License

MIT — see [LICENSE](LICENSE)
