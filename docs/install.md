# Install, update, remove

## Before you start

- Claude Code and git.
- Obsidian, if you want to browse the vault and watch the graph. Chickadee works without it.
- On Windows, Git for Windows. Chickadee's helper scripts and the live graph hook run in its Git Bash; without it they do not run.

## Install

From a terminal:

```sh
claude plugin marketplace add LJASP-studio/chickadee
claude plugin install chickadee@chickadee
```

Or inside Claude Code:

```
/plugin marketplace add LJASP-studio/chickadee
/plugin install chickadee@chickadee
```

Inside Claude Code, `/plugin install` opens a panel where you pick the scope; "user" makes Chickadee available in every folder. If you installed from a terminal while Claude Code was open, run `/reload-plugins` there or restart it.

Only `/chickadee:note` is in Claude's context in every session: its name and one-line description, well under 100 tokens. Setup, scan and check load only when you run them, and a skill's full text loads only when it runs.

## Set up

1. Open Claude Code in the folder that holds your projects, for example `~/code`, not inside one of them. The vault becomes a subfolder there. If your projects live in different places, use the folder they share, or move them under one.
2. Run `/chickadee:setup`. It asks everything in one message: note language, vault folder name, what Claude may read in each project and which files it never reads. Reply `ok` to take its suggestions.
3. Run `/chickadee:scan`. It reads each project with a read-only helper, shows you a plan and writes nothing until you say OK. A large workspace takes a while the first time; later scans read only what changed.

Setup changes three things on your machine:

- `brain/`: the vault, a local git repository with no remote.
- `CLAUDE.md` in the projects folder: a short block between `<!-- chickadee:start -->` and `<!-- chickadee:end -->` that tells Claude to look in the vault before the code.
- `.claude/settings.json` in the projects folder: read-deny rules for secrets, build output and any project you set to `none`. They apply to sessions started in the projects folder; a session started inside one project reads that project's own settings.

## Obsidian

Open the vault with "Open folder as vault". For the live graph, run `/chickadee:setup live`, then in Obsidian go to Settings → Community plugins, turn off Restricted mode and enable "Chickadee live graph". It needs Obsidian 1.15 or later.

The hook behind the live graph runs only after Claude reads or writes a Markdown file or runs a search, and writes nothing unless the Obsidian plugin is enabled in a vault near the project.

## Update

```sh
claude plugin marketplace update chickadee
claude plugin update chickadee@chickadee
```

Then run `/reload-plugins` or restart Claude Code. If you use the live graph, run `/chickadee:setup live` again to update the Obsidian plugin.

A vault set up before 0.8.0 has no review table and a decision table without the status column: `/chickadee:setup views` adds the missing views and asks before it replaces the decision table.

To get updates without these commands, open `/plugin`, go to Marketplaces, choose chickadee and turn on auto-update. It is off by default for plugins outside Anthropic's own marketplace.

## Moving over from engram

Chickadee was called engram before 0.7.0. Your vault keeps working as it is; only the plugin's name and commands change. Swap the plugin:

```sh
claude plugin uninstall engram@engram
claude plugin marketplace remove engram
claude plugin marketplace add LJASP-studio/chickadee
claude plugin install chickadee@chickadee
```

If you updated the old marketplace first and the plugin now fails to load, the same commands fix it. Then run `/chickadee:setup` once in your projects folder. It shows a short plan and, after your OK, renames `.engram.json` to `.chickadee.json`, updates the routing block's markers and commands, and installs the live graph plugin under its new name with your settings. When you enable "Chickadee live graph" in Obsidian, it turns the old "engram live graph" off. No note is touched. Until you do, every skill reads the old `.engram.json`.

## Remove

```sh
claude plugin uninstall chickadee@chickadee
claude plugin marketplace remove chickadee
```

The vault stays where it is: plain Markdown you can keep, open in Obsidian or delete. To undo the rest, remove the Chickadee block from `CLAUDE.md` and any read-deny rules you no longer want from `.claude/settings.json`.

## If something goes wrong

- `/chickadee:setup` is not in the list: run `/reload-plugins`, or restart Claude Code.
- Setup stops because the folder is inside a git repository: the vault would end up in that repository's history. Open Claude Code one folder up.
- Scan asks about a folder: the folder is new since setup. Choose `full`, `structure` or `none`; the answer is kept.
- On Windows, `sh` is not found: install Git for Windows and restart Claude Code.
- Anything else: open an issue with what you ran and what you saw.
