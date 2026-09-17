# Contributing

## Development setup
1. Clone the repo
2. Ensure `yq` (v4+) and `bats-core` are installed
3. Run tests: `bats tests/`

## Adding a new check
1. Add a config key under the relevant section in `config/settings.yaml`
2. Write a `check_<name>()` function following the existing pattern (PASS/FAIL result, JSON + human output, append to `RESULTS`, set `OVERALL_STATUS` on failure)
3. Call it in the main execution block at the bottom of `security-audit.sh`
4. Add a corresponding test in `tests/security-audit.bats`
5. Update `CHANGELOG.md`

## Style
- `set -euo pipefail` at the top of every script
- No hardcoded paths — derive everything from `$SCRIPT_DIR`/config
- Every check must support both human and `--json` output
