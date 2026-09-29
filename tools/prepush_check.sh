#!/usr/bin/env bash
# Pre-push safety check: run before anything is published to a public remote (D-13, T-01-06).
# Usage: bash tools/prepush_check.sh
#
# Exits non-zero if the repository, in its current tree OR anywhere in the history of any ref
# (git log --all), contains:
#   - local tooling or generated output: .claude/ (except .claude/CLAUDE.md), .tools/, .godot/,
#     files under build/ or screenshots/ (except their .gdignore), settings.local.json, .env
#   - a credential-shaped string (token VALUE formats only, never variable names); also runs
#     gitleaks when it is installed
#   - a blob larger than 5 MB (a Git LFS pointer is ~130 bytes, so this flags un-routed binaries)
# It always prints what would become public: tracked-file count, top-level tracked directories,
# refs covered, and the distinct author/committer identities, for the owner to review.
set -u

# shellcheck source=tools/_common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)/_common.sh"
cd "${DUSKHOLD_ROOT}" || exit 1

fail=0

# --- path rules --------------------------------------------------------------------------------
# Reads paths on stdin, prints the ones that must never be published.
forbidden_paths() {
  grep -E -e '^\.claude/' -e '^\.tools/' -e '^\.godot/' -e '^build/' -e '^screenshots/' \
    -e '(^|/)settings\.local\.json$' -e '(^|/)\.env$' \
    | grep -v -x -e '\.claude/CLAUDE\.md' -e 'build/\.gdignore' -e 'screenshots/\.gdignore'
}

echo "== Refs covered =="
git for-each-ref --format='%(refname:short)' | sed 's/^/  /'

echo
echo "== Tracked paths (working tree index) =="
bad="$(git ls-files | forbidden_paths || true)"
if [ -n "${bad}" ]; then
  echo "FAIL: tracked files that must not be published:" >&2
  echo "${bad}" | sed 's/^/  /' >&2
  fail=1
else
  echo "  OK: no tooling, generated output or local settings are tracked"
fi

echo
echo "== Paths anywhere in history =="
bad_hist="$(git log --all --name-only --format= | sort -u | forbidden_paths || true)"
if [ -n "${bad_hist}" ]; then
  echo "FAIL: history contains paths that must not be published:" >&2
  echo "${bad_hist}" | sed 's/^/  /' >&2
  fail=1
else
  echo "  OK: no forbidden path was ever committed on any ref"
fi

# --- credential scan ---------------------------------------------------------------------------
# Token VALUE formats only. Each pattern is written so this file does not match itself.
echo
echo "== Credential scan (full history, all refs) =="
# Covered: PEM private keys, GitHub tokens (ghp/gho/ghu/ghs/ghr and fine-grained), AWS access keys,
# Slack tokens and webhook URLs, OpenAI-style sk- keys, Stripe sk_/rk_ live/test keys, Google API
# keys, npm tokens.
CRED_RE='-----BEGIN [A-Z ]*PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|xox[abprs]-[0-9A-Za-z-]{10,}|(^|[^A-Za-z0-9])sk-[A-Za-z0-9_-]{20,}|(sk|rk)_(live|test)_[A-Za-z0-9]{16,}|AIza[0-9A-Za-z_-]{35}|npm_[A-Za-z0-9]{36}|hooks\.slack\.com/services/T[A-Z0-9]{8,}/B[A-Z0-9]{8,}/[A-Za-z0-9]{20,}'
hits="$(git log -p --all --no-color 2>/dev/null | grep -noE -e "${CRED_RE}" | sed -E 's/^([0-9]+:.{0,8}).*/\1.../' || true)"
if [ -n "${hits}" ]; then
  echo "FAIL: credential-shaped strings found in history (patch line number and first 8 chars only; the rest is masked):" >&2
  echo "${hits}" | head -20 | sed 's/^/  /' >&2
  fail=1
else
  echo "  OK: no credential-shaped strings"
fi
# The regex scan only sees added text lines: LFS-tracked files and binary blobs are not inspected.
# A maintained scanner covers far more formats, so run it too when it is installed.
if command -v gitleaks >/dev/null 2>&1; then
  if gitleaks detect --no-banner --redact --source . >/dev/null 2>&1; then
    echo "  OK: gitleaks found no leaks"
  else
    echo "FAIL: gitleaks reported leaks (run: gitleaks detect --redact --source . for details)" >&2
    fail=1
  fi
else
  echo "  NOTE: gitleaks not installed; LFS and binary contents were not scanned (recommended: install gitleaks)"
fi

# --- oversized blobs ---------------------------------------------------------------------------
echo
echo "== Blobs over 5 MB (history, all refs) =="
big="$(git rev-list --objects --all \
  | git cat-file --batch-check='%(objecttype) %(objectsize) %(rest)' \
  | awk '$1 == "blob" && $2 > 5242880 { print $2 " bytes  " $3 }' || true)"
if [ -n "${big}" ]; then
  echo "FAIL: blobs over 5 MB that are not LFS pointers:" >&2
  echo "${big}" | sed 's/^/  /' >&2
  fail=1
else
  echo "  OK: every large binary is routed through Git LFS"
fi

# --- what becomes public -----------------------------------------------------------------------
echo
echo "== What would become public =="
echo "Tracked files: $(git ls-files | wc -l | tr -d ' ')"
echo "Top-level tracked entries:"
git ls-files | awk -F/ '{ if (NF > 1) print $1 "/"; else print $1 }' | sort | uniq -c | awk '{ printf "  %5d  %s\n", $1, $2 }'
echo "Commits (all refs): $(git rev-list --all --count)"
echo "Distinct author identities:"
git log --all --format='%an <%ae>' | sort -u | sed 's/^/  /'
echo "Distinct committer identities:"
git log --all --format='%cn <%ce>' | sort -u | sed 's/^/  /'

echo
if [ "${fail}" -ne 0 ]; then
  echo "PREPUSH CHECK FAILED" >&2
  exit 1
fi
echo "PREPUSH CHECK PASSED"
exit 0
