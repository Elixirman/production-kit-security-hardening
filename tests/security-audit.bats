#!/usr/bin/env bats

SCRIPT="${BATS_TEST_DIRNAME}/../scripts/security-audit.sh"

@test "script exists and is executable" {
  [ -x "$SCRIPT" ]
}

@test "--help prints usage and exits 0" {
  run "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "--version prints version string" {
  run "$SCRIPT" --version
  [ "$status" -eq 0 ]
  [[ "$output" == *"security-audit.sh v"* ]]
}

@test "unknown flag exits 1 with usage" {
  run "$SCRIPT" --bogus-flag
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown option"* ]]
}

@test "--json mode produces valid JSON array" {
  run "$SCRIPT" --json
  # exit status may be 0 or 1 depending on this machine's actual security posture —
  # we're only checking the output shape here, not the pass/fail content
  [[ "$output" == \[*\] ]]
}

@test "default mode produces human-readable check lines" {
  run "$SCRIPT"
  [[ "$output" == *"check"* ]]
}
