#!/usr/bin/env bash
# Checks the Patterned rules a compiler cannot:
#   1. Engine words (FSRS, BKT, CPA, Wolfram, Gemini, SHA, KORA, Constitution, Council, streaks, XP)
#      appear in user-visible strings only in Settings, under "For the grown-up".
#   2. Seed copy a reader sees names no library and no method label (`@saxster/atlas`,
#      "Symbolic Lockstep"); fix the wording in the seed pack, not at display time.
#   3. A screen has at most one filled button (InkButtonStyle or BrassButtonStyle). A file that
#      holds more than one screen (a room and its sheet) is listed in FILLED_LIMIT with its count.
# Usage: scripts/check-design.sh [file ...]   (default: every Swift file under KymMaths/Features)
set -uo pipefail
cd "$(dirname "$0")/.."

JARGON='FSRS|BKT|Bayesian|\bCPA\b|Wolfram|Gemini|OpenAI|SHA-?256|KORA|Constitution|Council|Streak|\bXP\b|Brilliant|Mastery'
GROWN_UP='KymMaths/Features/Settings/'

# file → filled buttons allowed, for files that draw more than one screen.
FILLED_LIMIT=(
  "KymMaths/Features/Today/TodayHomeView.swift:2"
)

limit_for() {
  local f="$1" entry
  for entry in "${FILLED_LIMIT[@]}"; do
    [[ "${entry%%:*}" == "$f" ]] && { echo "${entry##*:}"; return; }
  done
  echo 1
}

if [[ $# -gt 0 ]]; then files=("$@"); else
  files=()
  while IFS= read -r f; do files+=("$f"); done < <(find KymMaths/Features -name '*.swift' | sort)
fi

status=0
for f in "${files[@]}"; do
  if [[ "$f" != "$GROWN_UP"* ]]; then
    # String literals on non-comment lines that name an engine.
    hits=$(grep -nE '"[^"]*"' "$f" | grep -vE '^[0-9]+:\s*//' | grep -E "\"[^\"]*($JARGON)[^\"]*\"" || true)
    if [[ -n "$hits" ]]; then
      echo "jargon outside Settings in $f:"
      echo "$hits" | sed 's/^/  /'
      status=1
    fi
  fi
  filled=$(grep -cE 'InkButtonStyle\(|BrassButtonStyle\(' "$f" || true)
  allowed=$(limit_for "$f")
  if (( filled > allowed )); then
    echo "$f has $filled filled buttons; a screen gets one (allowed here: $allowed)"
    status=1
  fi
done

COPY_LEAKS='@saxster/atlas|Symbolic Lockstep|Pictorial Intuition|Concrete → Pictorial|"subtitle": ?"OUP'
for f in KymMaths/Resources/ContentPacks/kymmaths-seed-pack.json KymMaths/Resources/PatternedWorldBook/index.html; do
  leaks=$(grep -oE "$COPY_LEAKS" "$f" | sort | uniq -c || true)
  if [[ -n "$leaks" ]]; then
    echo "reader-visible copy leaks in $f:"
    echo "$leaks" | sed 's/^/  /'
    status=1
  fi
done

if (( status == 0 )); then echo "check-design: ${#files[@]} files and the seed copy clean"; fi
exit $status
