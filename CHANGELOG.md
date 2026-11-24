# Changelog

## 0.8.1 - 2026-11-24

- The status note templates wrote a description with an unquoted `: `, which YAML cannot read, so Obsidian and Bases showed every status note without properties. The templates and the example vault now quote it, and the conventions say when a value needs quotes.
- `/chickadee:check` warns about frontmatter values YAML cannot read (`YAML_INVALID`: an unquoted `: `, a value that starts with `@` or a backtick, text after a closing quote, a bracket inside a flow list item) and its fix quotes them in a commit of its own (`chore: fix frontmatter`), which the staleness check does not count as a review.
- `/chickadee:setup views` also points out a view that filters on a folder the vault no longer has.

## 0.8.0 - 2026-11-24

- Decisions that no longer hold say so. A note can carry `status` (`proposed`, `accepted`, `deprecated`, `superseded`), `superseded_by` (a link to the note that replaced it) and `stale_after` (a date to look at it again). A replaced note's description starts with "Superseded by <new note>:" (in Turkish "Yerini <new note> aldı:"), so the first search already shows Claude it is out of date. The routing block is unchanged. All three keys are optional; vaults without them work as before.
- `/chickadee:note` marks the decision a new one replaces, and after a task it looks up the notes whose `code:` lists the files the task changed (new helper `skills/note/scripts/touched.sh`), corrects the ones that are now wrong and records the review on the ones that are still right. Tech and concept notes, hubs, release, research, daily and status notes are left out, since they record a moment or list many paths.
- `/chickadee:check` checks the new keys: a `superseded_by` that names no note is an error; an unknown status, a superseded note without a target, a description that does not say the note is out of date and a passed `stale_after` are warnings. Superseded and deprecated notes are no longer reported as stale, and its duplicate pass also looks for decisions a later note replaced.
- Views: the decision table has a "Current" view without superseded and deprecated decisions and an "All" view with their status, and a new review table lists superseded notes, notes past their review date, inferred decisions, pending proposals and status notes. `/chickadee:setup views` adds them to an existing vault; it replaces an existing decision table only on a yes.
- The example vault has a decision that a later one replaced.

## 0.7.0 - 2026-11-23

- engram is now Chickadee. The plugin and its marketplace are `chickadee`, the commands `/chickadee:setup`, `/chickadee:scan`, `/chickadee:note` and `/chickadee:check`, and the repository github.com/LJASP-studio/chickadee; old links redirect. To move an engram install over, see "Moving over from engram" in `docs/install.md`.
- Vaults set up by engram keep working. Every skill and the check script read `.engram.json` when there is no `.chickadee.json`, and `/chickadee:setup` on such a vault offers a short upgrade: it renames the config, renames the routing block's markers and commands without touching the rest of the block, and installs the live graph under its new name. No note is touched. The marketplace lists the old plugin name under `renames`, so Claude Code carries an old install's enabled setting over to the new name.
- Live graph: the Obsidian plugin is now "Chickadee live graph" (`chickadee-live`) and says it needs Obsidian 1.15, the version whose graph internals it uses (it said 1.5.0). If the old `engram-live` is still enabled, the new plugin copies its settings once and turns it off. The hook writes for both folders, so a vault still on the old plugin keeps its live graph.
- The live graph hook runs only after Claude reads or writes a Markdown file or runs a search (the Grep tool, or grep or rg in the shell), no longer after every tool call, and always in Git Bash on Windows instead of falling back to PowerShell.
- Listing: `plugin.json` has a display name, a homepage, an icon and the `claude-code` keyword, and the marketplace entry carries the same description. New `SECURITY.md`, `CONTRIBUTING.md` and a bug report template.
- Docs: the README shows an example note, lists Git for Windows under Get started and says read-deny rules hold in sessions started in the projects folder, while a session started inside one project reads that project's own settings. `docs/install.md` says only `note` is in every session's context, not all four skills. `reference/conventions.md` documents the config's `fields` and `tags` keys, and check and scan pass `fields.date` to the check script. The example vault's status notes have sourced lines.

## 0.6.1 - 2026-11-10

- The repository moved to github.com/LJASP-studio/engram. New installs use `claude plugin marketplace add LJASP-studio/engram`. Existing installs and old `muazfurkan/engram` links keep working through GitHub's redirect; nothing else changed.

## 0.6.0 - 2026-11-07

- Easier setup: `/engram:setup` asks everything in one message (note language, vault folder, what Claude may read in each project, files it never reads), each line with a suggestion, so `ok` takes them all. It no longer asks about Claude attribution in commits, which has nothing to do with the vault. Its report is shorter and ends with the next step.
- New `docs/install.md`: installing from a terminal or inside Claude Code, what setup changes on your machine, Obsidian, updating (and auto-update), removing, Windows and common problems. The README's Get started section is now three numbered steps.

## 0.5.0 - 2026-11-07

- Ready to be public: MIT license (`LICENSE`, `license` in `plugin.json`), install steps without the private-repository part, and a note that Windows support has not been tried on a real Windows machine yet.
- README: a section on what a vault changes, from a 60-question measurement on current models. Cost came out the same with and without the vault; answers about history, decisions and links between projects were more accurate; change-plan answers missed some files. The 46 percent token saving reported in 0.2.0 was measured on the previous model generation and did not hold on current models.
- No change to the skills, the routing block or the live graph: none of the routing changes measured after 0.4.1 lowered the cost, and the one that raised accuracy did not repeat on a separate question set.

## 0.4.1 - 2026-11-05

- Live graph shows searches too: notes whose lines a search returned (the Grep tool, or grep and rg run in Bash) glow faintly in their own color, notes Claude opens glow bright, and the counter adds how many notes matched. With description-first routing many questions are answered from the description lines alone, so before this the graph often stayed dark. The hook now also runs after Grep and Bash; it reads only the paths at the start of the output lines, never the text, and still writes nothing outside the vault. Glob is not shown. A setting turns search matches off.

## 0.4.0 - 2026-11-05

- Live graph: an Obsidian plugin (`obsidian/engram-live/`) that shows Claude's work on the vault in the graph view. A note Claude reads lights up in one color, an edited or new note in another; lit notes glow while Claude works, sparks run along their links, the other notes dim, and a counter shows notes read out of all notes. When Claude finishes its turn, everything fades out slowly.
- The plugin gets its events from a new hook in this plugin (`hooks/hooks.json`, `hooks/live.sh`): after Read, Edit and Write, and when a turn stops, it appends one line (tool, path inside the vault, session id) to `live.jsonl` in the Obsidian plugin's folder. The hook runs in the background, prints nothing and does nothing unless that file exists, which the Obsidian plugin creates only while it is enabled. No network, no file contents, no paths outside the vault; it stops appending past 1 MB.
- `/engram:setup live` copies the Obsidian plugin into the vault.

## 0.3.0 - 2026-11-05

- Privacy per machine: `setup` asks for each project folder whether its contents may be read (`full`), only its file names (`structure`, notes marked `visibility: internal`) or nothing (`none`), plus file patterns never read anywhere (`.env`, keys, certificates, credentials). Stored in `.engram.json` under `privacy` and written as `Read` deny rules into the projects folder's `.claude/settings.json`. `/engram:setup privacy` changes both; `scan` asks about new folders before reading them.
- Your edits are protected: before writing, every skill commits pending vault changes as `chore: snapshot manual edits`, and git history tells the user's edits from engram's. On a note the user edited, engram only adds lines; anything else becomes a proposal in `Proposals/` that the user applies or drops. New helper `skills/scan/scripts/edited.sh` lists those notes.
- `scan` shows a plan (new notes, updates, proposals, status notes, inferred decisions) and writes nothing before the user's OK.
- Status note per project (now, next, open questions, tried and did not work): `scan` creates it from a status file or an `Unreleased` changelog section only, `note` adds the outcome of each task.
- Decisions whose only sources are commits or tags carry `confidence: inferred` until the user confirms them.
- New checks: `MISSING_SOURCE`, `CODE_PATH_MISSING` and `PROJECTS_ROOT_MISSING` (errors), `STALE` (code under a note changed since the project's last scan and since the note was written), `INFERRED_UNMARKED`, `PROPOSAL_PENDING`, `PRIVACY_UNSET`, `PRIVACY_MISMATCH`, `PRIVACY_NONE_NOTES` (warnings), and an `INFERRED` count. `lint.sh` now reads `.engram.json`.
- Notes may be renamed, moved and merged when every link is updated in the same step, each change is its own commit and the check is clean afterwards; a merge that removes a file asks first.
- README: employer policy before sending work code to an LLM, no vault in iCloud Drive on Windows, pause file sync during bulk writes.

## 0.2.0 - 2026-11-05

- Concept notes: a `Concepts` folder for themes that notes in two or more projects share (security, privacy, determinism, localisation). Conventions, layout, hub templates, graph preset and the example vault have it; `scan` writes concept notes after the merge and `note` adds new notes to them.
- `scan` splits a large project into two briefs (documents and code map; history, decisions and data) so a subagent does not run out of context.
- Routing block and retrieval order are description-first: grep `^description:` with the `code:` lines, and read the hub and folder indexes only for broad questions. Measured on a real workspace (13 questions, two runs per question and order, against the same workspace without a vault), the old hub-first order used 18 percent fewer tokens and was cheaper on only 5 of 13 questions; description-first used 46 percent fewer tokens, 54 percent lower cost and 7 turns instead of 10, cheaper on 11 of 13. (Measured on the previous model generation; on current models the saving did not hold, see 0.5.0.)
- Scan brief: related notes go in `links:` only, and a hub update carries only its lead text, so merged hubs do not get a second content list.

## 0.1.0 - 2026-11-05

- First version of the `engram` plugin: `setup` (set up a vault), `scan` (scan projects), `note` (write a note), `check` (health check).
- `reference/conventions.md`: note format, vault layout, retrieval order, writing rules, types.
- `skills/check/scripts/lint.sh`: POSIX sh checks for missing fields, broken links, orphans, index and daily-note coverage, likely duplicates; tests in `tests/run.sh`.
- English vault structure with note text in English or Turkish; Obsidian graph preset and Bases views.
- Synthetic example projects and the vault built from them.
