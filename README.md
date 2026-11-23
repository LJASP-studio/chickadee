# Chickadee

<sub>formerly engram</sub>

Claude Code forgets your projects between sessions. Chickadee gives it a memory: an Obsidian vault of short, linked notes about why things are the way they are, when they changed and where they live in the code.

<p align="center"><img src="assets/live-graph.gif" alt="The live graph in Obsidian: a vault grows note by note, then Claude answers a question by opening only 3 of 377 notes" width="720"></p>

## What you get

- Answers about your own history. Ask "why did we move sessions to Redis?" or "when did the export change?" and Claude finds the note, reads the reason and goes straight to the right file.
- Sessions that start where you left off. Every project gets a status note: what is in progress, what comes next, open questions, what was tried and did not work.
- More from cheaper models. With the vault, Haiku answered a set of 20 questions as fully as Opus, at about a fortieth of the cost.
- A graph that shows Claude at work. The optional live graph (`/chickadee:setup live`) lights up the notes Claude reads and edits in Obsidian, while it works.
- Control over what is read. You choose per project what Claude may read, nothing leaves your machine through Chickadee, and your own notes are never overwritten: changes to them come as proposals you accept or drop.
- Notes you can trust. Every note cites its source and date, and `/chickadee:check` flags missing sources, broken links and notes whose code has changed since.

## Get started

You need Claude Code and git; on Windows, Git for Windows, since the helpers run in its Git Bash. Obsidian is optional.

1. Install the plugin:
   ```sh
   claude plugin marketplace add LJASP-studio/chickadee
   claude plugin install chickadee@chickadee
   ```
2. Open Claude Code in the folder that holds your projects (for example `~/code`) and run `/chickadee:setup`. It asks everything in one message; reply `ok` to take its suggestions.
3. Run `/chickadee:scan`. It shows a plan and writes nothing before your OK.

From then on Claude looks in the vault before it searches the code, and when a task is done it writes down what changed (`/chickadee:note`, or just ask). Installing from inside Claude Code, updating, removing, moving over from engram and common problems: [docs/install.md](docs/install.md).

## How it works

Chickadee is a Claude Code plugin with four skills. The vault sits inside your projects folder, in a local git repository with no remote.

```
projects/
├── CLAUDE.md     + a short routing block
├── api/          your projects, untouched
├── web/
└── brain/        the vault: Projects, Decisions, Releases, Tech, Concepts, Daily, Log
```

| Skill | What it does |
|---|---|
| `/chickadee:setup` | Sets up the vault, the privacy level per project and the routing block. |
| `/chickadee:scan` | Reads your projects and proposes notes; later rescans only what changed. |
| `/chickadee:note` | After a task, writes what changed and updates the status note. |
| `/chickadee:check` | Health check, with fixes on request. |

A note from the [example vault](examples/vault):

```markdown
---
description: Optional sync client in src/sync/client.ts that PUTs document revisions to a self-hosted server; push only, no pull or conflict handling.
date: 2026-02-03
source: [inkwell/src/sync/client.ts, inkwell/CHANGELOG.md (0.2.0)]
code: [inkwell/src/sync/client.ts]
tags: [module]
---
# Inkwell sync client

`pushRevision(serverUrl, docId, body)` sends an HTTP PUT to `<server>/docs/<docId>`. There is no pull, no conflict handling and no response check. Added in [[Inkwell 0.2.0]].

Related: [[Inkwell]] · [[Network access]]
```

The routing block tells Claude to search the `description` lines first, open at most three notes and go to the code they name.

## The numbers

I measured it on my own workspace (several projects, about 370 notes) with 60 questions, asked with and without the vault on Claude Sonnet 5.5. Cost per question was the same, and per fully correct answer the vault came out about 10 percent cheaper. It helped most where the code is silent: history (15 vs 11 out of 16 fully correct), decisions (12 vs 10 out of 16) and questions across projects (12 vs 9 out of 14). It did worse on change plans, where Claude trusted the notes and missed files, so ask it to check the code for those. One workspace, so read this as a direction.

## Privacy

Each project folder is `full` (docs, code, git history), `structure` (file names only) or `none` (skipped), and `.env` files, keys and credentials are never read. Setup writes these as read-deny rules in the projects folder's `.claude/settings.json`, so they hold in every session you start there, not only during a scan. A session started inside one project reads that project's own settings instead. What a skill reads does go to the model, so check your employer's policy before you use Chickadee on work code. Keep the vault in a plain local folder (iCloud Drive on Windows can corrupt files) and pause file sync during a scan.

## Develop

```sh
sh tests/run.sh                    # shell helpers and the live graph hook
claude plugin validate . --strict
claude --plugin-dir .              # try it without installing
```

The note format and every rule are in [reference/conventions.md](reference/conventions.md); `examples/` holds two made-up projects and the vault built from them.

## License

[MIT](LICENSE)
