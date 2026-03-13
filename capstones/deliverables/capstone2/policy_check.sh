#!/bin/bash
# policy_check.sh — Fails if plan contains any destroy or replacement actions
PLAN_FILE="${1:-plan_dev.txt}"

# Mencari pattern "will be destroyed" ATAU "must be replaced"
if grep -qE "# .* (will be destroyed|must be replaced)" "$PLAN_FILE"; then
  echo "❌ POLICY VIOLATION: Plan contains destroy or replacement actions. Aborting."
  grep -E "# .* (will be destroyed|must be replaced)" "$PLAN_FILE"
  exit 1
else
  echo "✅ Policy check passed. No destroy or replacement actions found."
  exit 0
fi
