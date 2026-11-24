#!/bin/sh
# Tests for skills/check/scripts/lint.sh, skills/scan/scripts/edited.sh, skills/note/scripts/touched.sh
# and hooks/live.sh on synthetic vaults.
# POSIX sh; needs git. Usage: sh tests/run.sh

set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
LINT="$ROOT/skills/check/scripts/lint.sh"
EDITED="$ROOT/skills/scan/scripts/edited.sh"
LIVE="$ROOT/hooks/live.sh"
WORK=$(mktemp -d 2>/dev/null || mktemp -d -t chickadee-test)
trap 'rm -rf "$WORK"' EXIT INT TERM
FAILS=0
V="$WORK/v"

note() { # note PATH CONTENT... (relative to $V)
  mkdir -p "$V/$(dirname "$1")"
  p=$1; shift
  printf '%s\n' "$@" > "$V/$p"
}

expect() { # expect CHECK COUNT
  got=$(awk -F '\t' -v c="$1" '$1 == "SUMMARY" && $2 == c { print $3 }' "$WORK/out")
  if [ "$got" = "$2" ]; then echo "ok   $SCENARIO: $1 = $2"
  else echo "FAIL $SCENARIO: $1 expected $2, got ${got:-none}"; FAILS=$((FAILS + 1)); fi
}

expect_line() { # expect_line CHECK PATH
  if awk -F '\t' -v c="$1" -v p="$2" '$1 == c && $2 == p { found = 1 } END { exit !found }' "$WORK/out"
  then echo "ok   $SCENARIO: $1 $2"
  else echo "FAIL $SCENARIO: missing $1 $2"; FAILS=$((FAILS + 1)); fi
}

expect_out() { # expect_out LINE...: the exact lines of $WORK/out, in order
  printf '%s\n' "$@" > "$WORK/want"
  if cmp -s "$WORK/want" "$WORK/out"; then echo "ok   $SCENARIO: $(tr '\n' ' ' < "$WORK/want")"
  else echo "FAIL $SCENARIO: expected [$(tr '\n' ' ' < "$WORK/want")] got [$(tr '\n' ' ' < "$WORK/out")]"; FAILS=$((FAILS + 1)); fi
}

lint() { sh "$LINT" "$V" date Daily Home Log "$1" > "$WORK/out" || :; }

commit_at() { # commit_at DIR DATE MESSAGE: commit everything in DIR at a fixed time
  ( cd "$1" && git add -A &&
    GIT_AUTHOR_DATE="$2T12:00:00" GIT_COMMITTER_DATE="$2T12:00:00" \
      git -c user.name=test -c user.email=test@example.invalid commit -q -m "$3" )
}

# 1. A small vault for a made-up note-taking app, with one problem of each kind. No .chickadee.json.
note Home.md '---' 'description: Entry point.' 'date: 2026-01-01' 'tags: [moc]' '---' '# Home' \
  '- [[Projects]]' '- [[Decisions]]' '- [[Daily]]' 'Changes: [[Log]]'
note Log.md '---' 'description: Change log.' 'date: 2026-01-01' '---' '# Log' '- 2026-01-01 setup | Vault created'
note Projects/Projects.md '---' 'description: Projects index.' 'date: 2026-01-01' 'tags: [moc]' '---' \
  '- [[Inkwell]]: a markdown editor'
note Projects/Inkwell/Inkwell.md '---' 'description: Inkwell hub.' 'date: 2026-01-02' 'source: inkwell/README.md' '---' \
  '# Inkwell' '- [[Editor core|the editor]]' '- [[Sync service#Setup]]' '- [[Ghost note]]' '![[diagram.png]]'
note Projects/Inkwell/diagram.png 'not really a png'
note Projects/Inkwell/Editor\ core.md '---' 'description: The editing engine and its buffer model.' \
  'date: 2026-01-03' 'code: [inkwell/src/editor/]' '---' '# Editor core' 'Piece table.' \
  '```' 'example [[Not a link]]' '```' 'Inline `[[nope]]` is code.' 'Related: [[Inkwell]]'
note Projects/Inkwell/Sync\ service.md '---' 'date: 2026-01-04' 'source:' '  - inkwell/src/sync/' '---' \
  '# Sync service' 'Related: [[Inkwell]]'
note Projects/Inkwell/Export.md '---' 'description: Export to PDF and HTML.' 'source: [inkwell/README.md]' '---' \
  '# Export' 'Related: [[Inkwell]]'
note Decisions/Decisions.md '---' 'description: Decisions index.' 'date: 2026-01-01' 'tags: [moc]' '---' \
  '- [[2026-01-10 Use SQLite]]: local storage'
note "Decisions/2026-01-10 Use SQLite.md" '---' 'description: Local storage is SQLite, one file per vault.' \
  'date: 2026-01-10' 'source: [inkwell/docs/adr-1.md]' '---' 'Uses [[SQLite]].'
note "Decisions/2026-02-01 Use SQLite.md" '---' 'description: SQLite for storage again, written twice.' \
  'date: 2026-02-01' 'tags:' '  - decision' '---' 'Uses [[SQLite]].'
note Tech/SQLite.md '---' 'description: Embedded database.' 'date: 2026-01-10' 'source: https://sqlite.org' '---' 'See [[Raw]].'
note Tech/Raw.md '# Raw' 'No frontmatter here.'
note Daily/Daily.md '---' 'description: Daily index.' 'date: 2026-01-01' 'tags: [moc]' '---' '- [[2026-03-01]]'
note Daily/2026-03-01.md '---' 'description: What happened on 2026-03-01.' 'date: 2026-03-01' 'tags: [daily]' '---' \
  'Related: [[Inkwell]]'

SCENARIO=plain
lint 2026-03-01
expect MISSING_FRONTMATTER 1
expect MISSING_DESCRIPTION 1
expect MISSING_DATE 1
expect MISSING_SOURCE 2
expect BROKEN_LINK 1
expect ORPHAN 2
expect NOT_IN_MOC 2
expect NO_MOC 1
expect LIKELY_DUPLICATE 1
expect DUPLICATE_NAME 0
expect DAILY_CHECK_SKIPPED 1
expect CODE_PATH_MISSING 0
expect PRIVACY_UNSET 0
expect_line BROKEN_LINK Projects/Inkwell/Inkwell.md
expect_line ORPHAN Projects/Inkwell/Export.md
expect_line MISSING_FRONTMATTER Tech/Raw.md
expect_line MISSING_SOURCE "Projects/Inkwell/Editor core.md"
expect_line MISSING_SOURCE "Decisions/2026-02-01 Use SQLite.md"

# 2. Daily coverage: commit "yesterday", then change one body, one frontmatter only, and add a note.
SCENARIO=daily
( cd "$V" && git init -q )
commit_at "$V" 2026-02-28 init
printf 'More about the buffer.\n' >> "$V/Projects/Inkwell/Editor core.md"
sed 's/^description: Inkwell hub\./description: Inkwell, the editor app hub./' \
  "$V/Projects/Inkwell/Inkwell.md" > "$WORK/tmp" && mv "$WORK/tmp" "$V/Projects/Inkwell/Inkwell.md"
note Projects/Inkwell/Search.md '---' 'description: Full-text search.' 'date: 2026-03-01' '---' 'Related: [[Inkwell]]'
lint 2026-03-01
expect NOT_IN_DAILY 2
expect_line NOT_IN_DAILY "Projects/Inkwell/Editor core.md"
expect_line NOT_IN_DAILY Projects/Inkwell/Search.md
expect DAILY_CHECK_SKIPPED 0
expect DAILY_CHECK_BY_DATE 0

# 3. A workspace with .chickadee.json: a git project scanned at a known commit, a project set to
#    none, read-deny rules, code paths, decisions inferred from commits and a pending proposal.
SCENARIO=workspace
WS="$WORK/ws"; V="$WS/brain"
mkdir -p "$WS/app/src" "$WS/app/docs" "$WS/secret" "$WS/.claude"
printf 'a\n' > "$WS/app/src/a.ts"; printf 'b\n' > "$WS/app/src/b.ts"; printf 'docs\n' > "$WS/app/docs/guide.md"
printf 'plan\n' > "$WS/secret/plan.md"
( cd "$WS/app" && git init -q )
commit_at "$WS/app" 2026-01-01 "feat: first version"
SCANNED=$(git -C "$WS/app" rev-parse --short HEAD)
printf '%s\n' '{ "permissions": { "deny": [ "Read(./**/.env)", "Read(/secret/**)", "Read(/app/**)" ] } }' \
  > "$WS/.claude/settings.json"
note .chickadee.json '{' '  "version": 1,' '  "language": "en",' '  "projectsRoot": "..",' \
  '  "folders": { "projects": "Projects", "decisions": "Decisions", "daily": "Daily" },' \
  "  \"lastScan\": { \"app\": { \"commit\": \"$SCANNED\", \"date\": \"2026-01-01\" } }," \
  '  "privacy": {' '    "projects": { "app": "full", "secret": "none" },' \
  '    "exclude": [".env", "*.pem"]' '  }' '}'
note Home.md '---' 'description: Entry point.' 'date: 2026-01-02' 'tags: [moc]' '---' \
  '- [[Projects]] · [[Decisions]] · [[Daily]] · [[Log]]'
note Log.md '---' 'description: Change log.' 'date: 2026-01-02' '---' 'Back to [[Home]].'
note Daily/Daily.md '---' 'description: Daily index.' 'date: 2026-01-02' 'tags: [moc]' '---' 'Up: [[Home]]'
note Projects/Projects.md '---' 'description: Projects index.' 'date: 2026-01-02' 'tags: [moc]' '---' '- [[App]]'
note Projects/App/App.md '---' 'description: The app hub.' 'date: 2026-01-02' 'source: [app/docs/guide.md]' \
  'code: [app/src/]' 'tags: [project]' '---' '- [[Guide]] · [[Old module]] · [[Secret plan]] · [[Decisions]]'
note Projects/App/Guide.md '---' 'description: The user guide.' 'date: 2026-01-02' 'source: [app/docs/guide.md]' \
  'code: [app/docs/guide.md]' '---' 'Up: [[App]]'
note "Projects/App/Old module.md" '---' 'description: A module that was removed.' 'date: 2026-01-02' \
  'source: [app/docs/guide.md]' 'code:' '  - app/src/gone.ts' '  - app/src/b.ts' '---' 'Up: [[App]]'
note "Projects/App/Secret plan.md" '---' 'description: Should not exist.' 'date: 2026-01-02' \
  'source: [secret/plan.md]' '---' 'Up: [[App]]'
note Decisions/Decisions.md '---' 'description: Decisions index.' 'date: 2026-01-02' 'tags: [moc]' '---' \
  '- [[2026-01-01 Tabs]] · [[2026-01-01 Spaces]] · [[App]]'
note "Decisions/2026-01-01 Tabs.md" '---' 'description: Tabs, inferred from a commit.' 'date: 2026-01-01' \
  "source: [app@$SCANNED]" 'tags: [decision]' '---' 'Up: [[Decisions]]'
note "Decisions/2026-01-01 Spaces.md" '---' 'description: Spaces, inferred and marked.' 'date: 2026-01-01' \
  "source: [\"app@$SCANNED\"]" 'confidence: inferred' 'tags: [decision]' '---' 'Up: [[Decisions]]'
note Proposals/App.proposal.md '---' 'description: Proposed update to App.' 'date: 2026-01-02' \
  'tags: [proposal]' '---' '```markdown' '[[Nowhere]]' '```'
( cd "$V" && git init -q )
commit_at "$V" 2026-01-02 "docs: scan app"
printf 'a2\n' > "$WS/app/src/a.ts"
commit_at "$WS/app" 2026-01-03 "fix: change a"
lint 2026-01-04
expect CODE_PATH_MISSING 1
expect_line CODE_PATH_MISSING "Projects/App/Old module.md"
expect STALE 1
expect_line STALE Projects/App/App.md
expect INFERRED_UNMARKED 1
expect_line INFERRED_UNMARKED "Decisions/2026-01-01 Tabs.md"
expect INFERRED 1
expect PROPOSAL_PENDING 1
expect PRIVACY_MISMATCH 2
expect_line PRIVACY_MISMATCH app
expect_line PRIVACY_MISMATCH "*.pem"
expect PRIVACY_NONE_NOTES 1
expect_line PRIVACY_NONE_NOTES "Projects/App/Secret plan.md"
expect PRIVACY_UNSET 0
expect BROKEN_LINK 0
expect ORPHAN 0
expect DUPLICATE_NAME 0

# 4. edited.sh: which notes carry the user's own edits.
SCENARIO=edited
printf 'My own line.\n' >> "$V/Projects/App/Guide.md"
commit_at "$V" 2026-01-05 "chore: snapshot manual edits"
( cd "$V" && git mv Projects/App/Guide.md Projects/App/Handbook.md )
commit_at "$V" 2026-01-06 "docs: rename Guide to Handbook"
note Projects/App/Mine.md '---' 'description: Written in Obsidian.' '---'
commit_at "$V" 2026-01-07 "vault backup"
printf 'Typed today.\n' >> "$V/Projects/App/App.md"
note Projects/App/Draft.md 'not committed yet'
sh "$EDITED" "$V" > "$WORK/out"
expect_out Projects/App/App.md Projects/App/Draft.md Projects/App/Handbook.md Projects/App/Mine.md
sh "$EDITED" "$V" "Projects/App/Old module.md" "$V/Projects/App/Handbook.md" ./Projects/App/Mine.md > "$WORK/out"
expect_out Projects/App/Handbook.md Projects/App/Mine.md
if sh "$EDITED" "$V" Projects/App/Nope.md > "$WORK/out" 2>/dev/null; then
  echo "FAIL $SCENARIO: an unknown note should exit 2"; FAILS=$((FAILS + 1))
else echo "ok   $SCENARIO: an unknown note exits 2"; fi
commit_at "$V" 2026-01-08 "chore: snapshot manual edits"
note Projects/App/Merged.md '---' 'description: Gets a merge.' '---'
note Projects/App/Clean.md '---' 'description: Untouched.' '---'
commit_at "$V" 2026-01-09 "docs: add Merged and Clean"
printf 'Lines from Draft.\n' >> "$V/Projects/App/Merged.md"
( cd "$V" && git rm -q Projects/App/Draft.md )
commit_at "$V" 2026-01-10 "docs: merge Draft into Merged"
sh "$EDITED" "$V" Projects/App/Merged.md Projects/App/Clean.md > "$WORK/out"
expect_out Projects/App/Merged.md

# 5. lint edge cases: unindented YAML lists, a none folder whose name has a space, a wrong root.
SCENARIO=edge
mkdir -p "$WS/my app/src"; printf 'x\n' > "$WS/my app/src/x.ts"
( cd "$WS/my app" && git init -q ); commit_at "$WS/my app" 2026-01-01 "feat: x"
MYAPP=$(git -C "$WS/my app" rev-parse --short HEAD)
sed "s/\"app\": { \"commit\"/\"my app\": { \"commit\": \"$MYAPP\", \"date\": \"2026-01-01\" }, \"app\": { \"commit\"/; s/\"secret\": \"none\"/\"secret\": \"none\", \"my app\": \"none\"/" \
  "$V/.chickadee.json" > "$WORK/tmp" && mv "$WORK/tmp" "$V/.chickadee.json"
note Projects/App/Listed.md '---' 'description: Lists without indent.' 'date: 2026-01-11' 'source:' '- app/docs/guide.md' \
  'code:' '- app/src/missing.ts' '---' 'Up: [[App]]'
commit_at "$V" 2026-01-11 "docs: add Listed"
printf 'x2\n' > "$WS/my app/src/x.ts"; commit_at "$WS/my app" 2026-01-12 "fix: x"
lint 2026-01-12
expect_line CODE_PATH_MISSING Projects/App/Listed.md
if grep -q '^STALE.*my app' "$WORK/out"; then echo "FAIL $SCENARIO: lint looked inside a none folder"; FAILS=$((FAILS + 1))
else echo "ok   $SCENARIO: nothing from a none folder"; fi
expect PROJECTS_ROOT_MISSING 0
sed 's/"projectsRoot": ".."/"projectsRoot": "..\/nowhere"/' "$V/.chickadee.json" > "$WORK/tmp" && mv "$WORK/tmp" "$V/.chickadee.json"
lint 2026-01-12
expect PROJECTS_ROOT_MISSING 1
if grep -q "MISSING_SOURCE	Projects/App/Listed.md" "$WORK/out"; then echo "FAIL $SCENARIO: unindented source list not read"; FAILS=$((FAILS + 1))
else echo "ok   $SCENARIO: unindented source list read"; fi

# 6. A vault set up before 0.7.0 keeps its config as .engram.json: it is still read, and a
#    .chickadee.json next to it wins. projectsRoot points nowhere here, so the finding names the file.
SCENARIO=renamed
mv "$V/.chickadee.json" "$V/.engram.json"
lint 2026-01-12
expect PROJECTS_ROOT_MISSING 1
expect_line PROJECTS_ROOT_MISSING .engram.json
sed 's/"projectsRoot": "..\/nowhere"/"projectsRoot": ".."/' "$V/.engram.json" > "$V/.chickadee.json"
lint 2026-01-12
expect PROJECTS_ROOT_MISSING 0
expect_line PRIVACY_MISMATCH "my app"
if grep -q 'PRIVACY_MISMATCH.*\.engram\.json' "$WORK/out"; then echo "FAIL $SCENARIO: read .engram.json next to .chickadee.json"; FAILS=$((FAILS + 1))
else echo "ok   $SCENARIO: .chickadee.json wins over .engram.json"; fi

# 7. The example vault shipped in examples/ must stay clean.
SCENARIO=example
sh "$LINT" "$ROOT/examples/vault" date Daily Home Log 2026-11-05 > "$WORK/out" || :
for c in MISSING_FRONTMATTER MISSING_DESCRIPTION MISSING_DATE MISSING_SOURCE BROKEN_LINK ORPHAN NOT_IN_MOC \
         CODE_PATH_MISSING NO_MOC LIKELY_DUPLICATE INFERRED_UNMARKED PRIVACY_UNSET PRIVACY_MISMATCH \
         SUPERSEDED_BY_BROKEN STATUS_UNKNOWN SUPERSEDED_NO_TARGET SUPERSEDED_BY_MISMATCH \
         LIFECYCLE_NOT_IN_DESCRIPTION REVIEW_DUE STALE_AFTER_INVALID YAML_INVALID; do
  expect $c 0
done
expect RETIRED 1

# 7b. Decision lifecycle: status, superseded_by and stale_after. Old vaults have none of these
#     keys and must report nothing new (scenarios 1-7 above).
SCENARIO=lifecycle
V="$WORK/life"
note Home.md '---' 'description: Entry point.' 'date: 2026-01-01' 'tags: [moc]' '---' '- [[Decisions]] · [[Log]]'
note Log.md '---' 'description: Change log.' 'date: 2026-01-01' '---' 'Up: [[Home]]'
note Decisions/Decisions.md '---' 'description: Decisions index.' 'date: 2026-01-01' 'tags: [moc]' '---' \
  '- [[2026-01-01 Redis]] · [[2026-02-01 Postgres]] · [[2026-03-01 Sqlite]] · [[2026-01-05 Tabs]] · [[2026-01-06 Beta]]' \
  '- [[2026-01-07 Odd]] · [[2026-01-08 Lost]] · [[2026-01-09 Loose]] · [[2026-01-10 Typo]] · [[2026-01-11 Geri]]' \
  '- [[2026-01-12 Sessions in Redis]] · [[2026-01-13 Self]] · [[2026-01-01 Redis copy]]' 'Up: [[Home]]'
dec() { # dec TITLE DESCRIPTION EXTRA-FRONTMATTER-LINE...
  t=$1; d=$2; shift 2
  note "Decisions/$t.md" '---' "description: $d" 'date: 2026-01-01' 'source: [docs/adr.md]' 'tags: [decision]' "$@" '---' 'Up: [[Decisions]]'
}
dec "2026-01-01 Redis" "Superseded by 2026-02-01 Postgres: sessions in Redis." 'status: superseded' 'superseded_by: "[[2026-02-01 Postgres]]"'
dec "2026-02-01 Postgres" "Superseded by 2026-03-01 Sqlite: sessions in Postgres." 'status: superseded' 'superseded_by: "[[2026-03-01 Sqlite|the new one]]"'
dec "2026-03-01 Sqlite" "Sessions in SQLite." 'status: accepted' 'stale_after: 2026-12-31'
dec "2026-01-05 Tabs" "Geçersiz: girinti sekmeyle yapılırdı." 'status: deprecated' 'stale_after: 2026-01-02'
dec "2026-01-06 Beta" "The beta flag stays on until launch." "stale_after: '2026-01-02'"
dec "2026-01-07 Odd" "An odd status." 'status: Draft'
dec "2026-01-08 Lost" "Superseded by nothing that exists." 'status: superseded' 'superseded_by: "[[2026-09-09 Nowhere]]"'
dec "2026-01-09 Loose" "Points on but keeps its status." 'superseded_by: 2026-03-01 Sqlite'
dec "2026-01-10 Typo" "Forgot to say it was replaced." 'status: superseded' 'superseded_by: "[[2026-03-01 Sqlite]]"' 'stale_after: soon'
dec "2026-01-11 Geri" "Yerini 2026-03-01 Sqlite aldı: oturumlar dosyadaydı." 'status: superseded'
dec "2026-01-12 Sessions in Redis" "Deprecated: an older note on the same subject." 'status: deprecated'
dec "2026-01-13 Self" "Superseded by 2026-01-13 Self: loops." 'status: superseded' 'superseded_by: "[[2026-01-13 Self]]"'
note "Decisions/2026-01-01 Redis copy.md" '---' 'description: Superseded by 2026-02-01 Postgres: sessions in Redis.' 'date: 2026-01-01' \
  'tags: [decision]' 'status: superseded' 'superseded_by: "[[2026-02-01 Postgres]]"' '---' 'Up: [[Decisions]]'
lint 2026-06-01
expect SUPERSEDED_BY_BROKEN 2
expect_line SUPERSEDED_BY_BROKEN "Decisions/2026-01-08 Lost.md"
expect_line SUPERSEDED_BY_BROKEN "Decisions/2026-01-13 Self.md"
expect STATUS_UNKNOWN 1
expect_line STATUS_UNKNOWN "Decisions/2026-01-07 Odd.md"
expect SUPERSEDED_NO_TARGET 1
expect_line SUPERSEDED_NO_TARGET "Decisions/2026-01-11 Geri.md"
expect SUPERSEDED_BY_MISMATCH 1
expect_line SUPERSEDED_BY_MISMATCH "Decisions/2026-01-09 Loose.md"
expect LIFECYCLE_NOT_IN_DESCRIPTION 1
expect_line LIFECYCLE_NOT_IN_DESCRIPTION "Decisions/2026-01-10 Typo.md"
expect REVIEW_DUE 1
expect_line REVIEW_DUE "Decisions/2026-01-06 Beta.md"
expect STALE_AFTER_INVALID 1
expect_line STALE_AFTER_INVALID "Decisions/2026-01-10 Typo.md"
expect RETIRED 9
expect LIKELY_DUPLICATE 0
expect ORPHAN 0
expect BROKEN_LINK 0
lint 2027-01-01
expect REVIEW_DUE 2
expect_line REVIEW_DUE "Decisions/2026-03-01 Sqlite.md"

# 7b2. Frontmatter values YAML cannot read: Obsidian then shows the note without properties.
SCENARIO=yaml
V="$WORK/yaml"
note Home.md '---' 'description: Entry point.' 'date: 2026-01-01' 'tags: [moc]' '---' \
  '- [[Colon]] · [[Quoted]] · [[Tail]] · [[At]] · [[Bracket]] · [[Item]] · [[Fine]] · [[Single]]' 'Up: [[Log]]'
note Log.md '---' 'description: Change log.' 'date: 2026-01-01' '---' 'Up: [[Home]]'
y() { t=$1; shift; note "$t.md" '---' "$@" 'date: 2026-01-01' 'source: [docs/a.md]' '---' 'Up: [[Home]]'; }
y Colon 'description: Where it stands: now and next.'
y Quoted 'description: "Where it stands: now and next, with a \"quote\"."'
y Tail 'description: "Superseded by X" and more.'
y At 'description: @mention first.'
y Bracket 'description: Routes.' 'code: [src/pages/[...path].astro, src/a.ts]'
y Item 'description: Items.' 'code:' '  - "src/b.ts"' '  - note: a mapping'
y Fine 'description: Plain text, a URL https://example.com/a?b=c and a time 10:30.' 'code: [src/a.ts, "src/[id].ts", README.md (Is it safe?)]'
y Single "description: 'It''s fine: quoted.'"
lint 2026-01-02
expect YAML_INVALID 5
for n in Colon Tail At Bracket Item; do expect_line YAML_INVALID "$n.md"; done
if grep -qE 'YAML_INVALID.*(Quoted|Fine|Single)' "$WORK/out"; then echo "FAIL $SCENARIO: flagged a valid value"; FAILS=$((FAILS + 1))
else echo "ok   $SCENARIO: valid values pass"; fi

# 7c. touched.sh: which notes cite the files a piece of work changed.
SCENARIO=touched
TOUCHED="$ROOT/skills/note/scripts/touched.sh"
TW="$WORK/tw"; V="$TW/notes"
mkdir -p "$TW/app/src/auth" "$TW/app/docs"
printf 'x\n' > "$TW/app/src/auth/login.ts"; printf 'x\n' > "$TW/app/src/auth/token.ts"; printf 'x\n' > "$TW/app/docs/guide.md"
note .chickadee.json '{ "version": 1, "projectsRoot": "..", "folders": { "proposals": "Ideas" } }'
note Projects/App/App.md '---' 'description: Hub.' 'code: [app/src/auth/login.ts]' 'tags: [project]' '---'
note Projects/App/Overview.md '---' 'description: Overview.' 'code: [app/src/, app/docs/]' '---'
note Tech/TypeScript.md '---' 'description: Tech.' 'code: [app/src/auth/login.ts]' '---'
note Projects/App/Auth.md '---' 'description: Auth.' 'code:' '  - app/src/auth' '  - "app/docs/guide.md"' '---'
note Projects/App/Login.md '---' 'description: Login.' 'code: [app/src/auth/login.ts]' '---'
note Projects/App/Old login.md '---' 'description: Superseded by Login: old.' 'code: [app/src/auth/login.ts]' 'status: superseded' '---'
note Projects/App/Other.md '---' 'description: Other.' 'code: [app/src/authz/]' '---'
note Releases/App 1.0.md '---' 'description: Release.' 'code: [app/src/auth/login.ts]' 'tags: [release]' '---'
note Projects/Projects.md '---' 'description: Index.' 'code: [app/]' 'tags: [moc]' '---'
note Ideas/Login.proposal.md '---' 'description: Proposal.' 'code: [app/src/auth/login.ts]' '---'
sh "$TOUCHED" "$V" app/src/auth/login.ts > "$WORK/out"
expect_out "Projects/App/Login.md	app/src/auth/login.ts	app/src/auth/login.ts" \
  "Projects/App/Auth.md	app/src/auth	app/src/auth/login.ts" "Projects/App/Overview.md	app/src	app/src/auth/login.ts"
sh "$TOUCHED" "$V" "$TW/app/src/auth/" ./app/docs/guide.md > "$WORK/out"
expect_out "Projects/App/Login.md	app/src/auth/login.ts	app/src/auth" \
  "Projects/App/Auth.md	app/docs/guide.md	app/docs/guide.md" "Projects/App/Overview.md	app/docs	app/docs/guide.md"
sh "$TOUCHED" "$V" app/README.md > "$WORK/out"
if [ ! -s "$WORK/out" ]; then echo "ok   $SCENARIO: nothing for an uncited file"; else echo "FAIL $SCENARIO: printed notes for an uncited file"; FAILS=$((FAILS + 1)); fi
mv "$V/.chickadee.json" "$V/.engram.json"
sh "$TOUCHED" "$V" app/src/auth/token.ts > "$WORK/out"
expect_out "Projects/App/Auth.md	app/src/auth	app/src/auth/token.ts" "Projects/App/Overview.md	app/src	app/src/auth/token.ts"
if sh "$TOUCHED" "$V" > /dev/null 2>&1; then echo "FAIL $SCENARIO: no paths should exit 2"; FAILS=$((FAILS + 1))
else echo "ok   $SCENARIO: no paths exits 2"; fi

# 8. Live graph hook: one line per note read or written inside a vault whose plugin is on.
SCENARIO=live
L="$WORK/live"
LOG="$L/notes/.obsidian/plugins/chickadee-live/live.jsonl"
mkdir -p "$L/notes/Projects" "$L/notes-old" "$L/app/src"
hook() { # hook PROJECT_DIR JSON
  printf '%s' "$2" | CLAUDE_PROJECT_DIR="$1" sh "$LIVE"
}
read_json() { printf '{"session_id":"s1","cwd":"%s","tool_name":"%s","tool_input":{"file_path":"%s"}}' "$L" "$1" "$2"; }
hook "$L" "$(read_json Read "$L/notes/Home.md")"
if [ -e "$LOG" ]; then echo "FAIL $SCENARIO: wrote without the plugin's file"; FAILS=$((FAILS + 1))
else echo "ok   $SCENARIO: nothing without the plugin's file"; fi
mkdir -p "$(dirname "$LOG")"; : > "$LOG"
hook "$L" "$(read_json Read "$L/notes/Home.md")"
hook "$L/app/src" "$(read_json Edit "$L/notes/Projects/App.md")"
hook "$L" "$(read_json Write "$L/notes/./Projects/../Projects/New.md")"
hook "$L" '{"cwd":"'"$L"'","tool_name":"Read","tool_input":{"file_path":"notes/Rel.md"}}'
hook "$L" '{"tool_name":"Read","tool_input":{"file_path":"'"$L"'/notes/Projects/Çay \"ölçümü\".md"},"tool_response":{"file":{"content":"\"file_path\":\"x\""}}}'
hook "$L" '{"tool_name":"Grep","tool_input":{"pattern":"x","path":"'"$L"'/notes"}}'
hook "$L" "$(read_json Read "$L/app/src/x.ts")"
hook "$L" "$(read_json Read "$L/notes-old/Home.md")"
hook "$L" "$(read_json Read "$L/notes/.obsidian/graph.json")"
hook "$L/app" '{"session_id":"s2","hook_event_name":"Stop","stop_hook_active":false}'
cp "$LOG" "$WORK/out"
expect_out '{"v":1,"tool":"Read","path":"Home.md","session":"s1"}' '{"v":1,"tool":"Edit","path":"Projects/App.md","session":"s1"}' \
  '{"v":1,"tool":"Write","path":"Projects/New.md","session":"s1"}' '{"v":1,"tool":"Read","path":"Rel.md","session":""}' \
  '{"v":1,"tool":"Read","path":"Projects/Çay \"ölçümü\".md","session":""}' '{"v":1,"event":"stop","session":"s2"}'
: > "$LOG"
hook "$L" '{"session_id":"s3","cwd":"'"$L"'","tool_name":"Grep","tool_input":{"pattern":"^description:","path":"notes","output_mode":"content","-A":2},"tool_response":{"mode":"content","filenames":[],"content":"notes/Home.md:2:description: Entry.\nnotes/Home.md-3-date: x\n--\nnotes/Projects/App.md:2:description: An app.\napp/src/x.ts:1:description"}}'
hook "$L" '{"session_id":"s3","cwd":"'"$L"'","tool_name":"Grep","tool_input":{"pattern":"x","path":"notes"},"tool_response":{"mode":"files_with_matches","filenames":["notes/Projects/New.md","'"$L"'/notes/Rel.md","notes/.obsidian/x.md"]}}'
hook "$L/app" '{"session_id":"s3","cwd":"'"$L"'","tool_name":"Bash","tool_input":{"command":"grep -rn x notes"},"tool_response":{"stdout":"'"$L"'/notes/Projects/App.md:4:x\nnotes/Home.md\nnot a path\n","stderr":""}}'
cp "$LOG" "$WORK/out"
expect_out '{"v":1,"tool":"Grep","path":"Home.md","session":"s3"}' '{"v":1,"tool":"Grep","path":"Projects/App.md","session":"s3"}' \
  '{"v":1,"tool":"Grep","path":"Projects/New.md","session":"s3"}' '{"v":1,"tool":"Grep","path":"Rel.md","session":"s3"}' \
  '{"v":1,"tool":"Bash","path":"Projects/App.md","session":"s3"}' '{"v":1,"tool":"Bash","path":"Home.md","session":"s3"}'
head -c 1100000 /dev/zero | tr '\0' 'x' > "$LOG"
hook "$L" "$(read_json Read "$L/notes/Home.md")"
if [ "$(wc -c < "$LOG" | tr -d ' ')" -eq 1100000 ]; then echo "ok   $SCENARIO: no appending past 1 MB"
else echo "FAIL $SCENARIO: appended past 1 MB"; FAILS=$((FAILS + 1)); fi

# 9. The live graph plugin's folder before 0.7.0 (engram-live) is still served, next to the new one
#    or alone, and the hook is registered only for Markdown files and searches, always in bash.
SCENARIO=live-renamed
OLD="$L/notes/.obsidian/plugins/engram-live/live.jsonl"
mkdir -p "$(dirname "$OLD")"; : > "$OLD"; : > "$LOG"
hook "$L" "$(read_json Read "$L/notes/Home.md")"
cp "$OLD" "$WORK/out"
expect_out '{"v":1,"tool":"Read","path":"Home.md","session":"s1"}'
cp "$LOG" "$WORK/out"
expect_out '{"v":1,"tool":"Read","path":"Home.md","session":"s1"}'
rm "$LOG"; : > "$OLD"
hook "$L/app" "$(read_json Edit "$L/notes/Projects/App.md")"
hook "$L/app" '{"session_id":"s4","hook_event_name":"Stop"}'
cp "$OLD" "$WORK/out"
expect_out '{"v":1,"tool":"Edit","path":"Projects/App.md","session":"s1"}' '{"v":1,"event":"stop","session":"s4"}'
HOOKS="$ROOT/hooks/hooks.json"
cmds=$(grep -c '"command"' "$HOOKS"); bash=$(grep -c '"shell": "bash"' "$HOOKS"); ifs=$(grep -c '"if": "' "$HOOKS")
if [ "$cmds" = 7 ] && [ "$bash" = 7 ] && [ "$ifs" = 6 ]; then echo "ok   $SCENARIO: hooks run in bash, tool hooks only for notes and searches"
else echo "FAIL $SCENARIO: hooks.json has $cmds commands, $bash in bash, $ifs with if"; FAILS=$((FAILS + 1)); fi

if [ "$FAILS" -eq 0 ]; then echo "all tests passed"; else echo "$FAILS failed"; exit 1; fi
