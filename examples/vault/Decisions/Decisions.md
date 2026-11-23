---
description: Index of dated decision notes from all projects, explaining why the code is the way it is.
date: 2026-11-05
tags: [moc]
---
# Decisions

Decisions across all projects, one note each, file names start with the date.

- [[2026-01-10 Store Inkwell documents in SQLite]]: ADR 0001 keeps Inkwell documents and undo history in one SQLite file per vault, for atomic saves and FTS5 search.
- [[2026-02-02 tide-cli reads the harbour web page]]: Superseded by 2026-02-16 tide-cli reads a public tide table: tide times were read off the harbour's web page, no key, no extra source.
- [[2026-02-16 tide-cli reads a public tide table]]: tide-cli reads the national public tide table, whose format is fixed, after the harbour web page's layout broke the reader twice.

Up: [[Home]]
