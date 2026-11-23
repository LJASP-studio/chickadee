#!/bin/sh
# touched.sh: which vault notes describe the files a piece of work changed. POSIX sh + awk.
#
# Usage: touched.sh VAULT PATH...
#   PATH  a changed file or folder, relative to the projects root (projectsRoot in the vault's
#         .chickadee.json, or .engram.json before 0.7.0; default ..) or absolute inside it
#
# Prints one line per note whose `code` list covers a changed path: the code path is that file,
# a folder above it, or a file inside a changed folder. Format: note<TAB>code path<TAB>changed path,
# note relative to the vault, most specific code path first, so project hubs with a whole-folder
# code map come last. Left out: superseded and deprecated notes, proposals, tech and concept
# notes and folder notes (hubs and MOCs, which list many paths), and notes tagged moc, release,
# research, daily or status (they record a moment, not the code as it is).
# Reads only the notes' frontmatter; never opens a project file.
# Exit status: 0 (also when nothing matches), 2 on bad usage.

set -eu

if [ $# -lt 2 ] || [ ! -d "$1" ]; then
  echo "usage: touched.sh VAULT PATH..." >&2
  exit 2
fi
VAULT=$(cd "$1" && pwd -P); shift
TMP=$(mktemp -d 2>/dev/null || mktemp -d -t chickadee)
trap 'rm -rf "$TMP"' EXIT INT TERM

CFG="$VAULT/.chickadee.json"
[ ! -f "$CFG" ] && [ -f "$VAULT/.engram.json" ] && CFG="$VAULT/.engram.json"
rel=..; PROPOSALS=Proposals; TECH=Tech; CONCEPTS=Concepts
folder() { sed -n 's/.*"'"$1"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CFG" | head -n 1; }
if [ -f "$CFG" ]; then
  v=$(sed -n 's/.*"projectsRoot"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CFG" | head -n 1)
  [ -n "$v" ] && rel=$v
  v=$(sed -n 's/.*"proposals"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CFG" | head -n 1)
  [ -n "$v" ] && PROPOSALS=$v
  v=$(folder tech); [ -n "$v" ] && TECH=$v
  v=$(folder concepts); [ -n "$v" ] && CONCEPTS=$v
fi
ROOT=$(cd "$VAULT" && cd "$rel" 2>/dev/null && pwd -P || :)

# Changed paths, relative to the projects root, forward slashes, no ./ or trailing slash.
for p in "$@"; do
  p=$(printf '%s' "$p" | tr '\\' '/')
  case $p in /*|[A-Za-z]:/*)   # absolute: resolve symlinks the way ROOT was resolved
    if [ -d "$p" ]; then p=$(cd "$p" && pwd -P)
    elif [ -d "$(dirname "$p")" ]; then p=$(cd "$(dirname "$p")" && pwd -P)/$(basename "$p"); fi ;;
  esac
  case $p in
    "$ROOT"/*) p=${p#"$ROOT"/} ;;
    /*|[A-Za-z]:/*) echo "touched.sh: $p is outside the projects root $ROOT" >&2; continue ;;
  esac
  p=${p#./}
  while [ "${p%/}" != "$p" ]; do p=${p%/}; done
  [ -n "$p" ] && [ "$p" != . ] && printf '%s\n' "$p"
done > "$TMP/changed"

( cd "$VAULT" && find . \( -name .git -o -name .obsidian -o -name .trash \) -prune -o -type f -name '*.md' -print ) |
  sed 's|^\./||' | LC_ALL=C sort > "$TMP/notes"

LC_ALL=C awk -v notes="$TMP/notes" -v changedf="$TMP/changed" -v vault="$VAULT" -v root="$ROOT" -v proposals="$PROPOSALS" -v tech="$TECH" -v concepts="$CONCEPTS" '
function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
function unquote(s) {
  s = trim(s)
  if (s ~ /^".*"$/ || s ~ /^\047.*\047$/) s = substr(s, 2, length(s) - 2)
  return s
}
function add(f, key, item) {
  item = unquote(item); sub(/^\.\//, "", item)
  if (item == "") return
  if (key == "tags") { tag[f, item] = 1; return }
  ncode[f]++; code[f, ncode[f]] = item
}
function additems(f, key, v,   i, c, q, item, n) {
  v = trim(v)
  if (v == "") return
  if (v !~ /^\[/) { add(f, key, v); return }
  v = substr(v, 2); sub(/\][ \t]*$/, "", v)
  item = ""; q = ""; n = length(v)
  for (i = 1; i <= n; i++) {
    c = substr(v, i, 1)
    if (q != "") { if (c == q) q = ""; item = item c; continue }
    if (c == "\"" || c == "\047") { q = c; item = item c; continue }
    if (c == ",") { add(f, key, item); item = ""; continue }
    item = item c
  }
  add(f, key, item)
}
function isdir(p) { return p ~ /\/$/ || system("test -d \"" root "/" p "\"") == 0 }
BEGIN {
  while ((getline c < changedf) > 0) chg[++nchg] = c
  close(changedf)
  while ((getline f < notes) > 0) {
    if (index(f, proposals "/") == 1 || index(f, tech "/") == 1 || index(f, concepts "/") == 1) continue
    hb = f; sub(/\.md$/, "", hb); nparts = split(hb, part, "/")
    if (nparts > 1 && part[nparts] == part[nparts - 1]) continue   # a folder note: hub or MOC
    n = 0; fm = 0; cur = ""; st = ""
    while ((getline line < (vault "/" f)) > 0) {
      n++; sub(/\r$/, "", line)
      if (n == 1) { if (line != "---") break; fm = 1; continue }
      if (line == "---") break
      if (cur != "" && line ~ /^[ \t]*- /) { v = line; sub(/^[ \t]*- /, "", v); add(f, cur, v); continue }
      cur = ""
      if (line !~ /^[A-Za-z_][A-Za-z0-9_-]*:/) continue
      k = line; sub(/:.*/, "", k)
      v = line; sub(/^[^:]*:/, "", v); v = trim(v)
      if (k == "status") st = tolower(unquote(v))
      if (k == "code" || k == "tags") { if (v == "") cur = k; else additems(f, k, v) }
    }
    close(vault "/" f)
    if (st == "superseded" || st == "deprecated") continue
    if (((f, "moc") in tag) || ((f, "release") in tag) || ((f, "research") in tag) || ((f, "daily") in tag) || ((f, "status") in tag)) continue
    best = ""; bestchg = ""
    for (j = 1; j <= ncode[f]; j++) {
      cp = code[f, j]; base = cp; sub(/\/+$/, "", base)
      for (i = 1; i <= nchg; i++) {
        c = chg[i]
        hit = (c == base) || (index(c, base "/") == 1 && isdir(cp)) || index(base, c "/") == 1
        if (hit && length(base) > length(best)) { best = base; bestchg = c }
      }
    }
    if (best != "") printf "%d\t%s\t%s\t%s\n", length(best), f, best, bestchg
  }
}' | sort -t "$(printf '\t')" -k1,1nr -k2,2 | cut -f 2-
