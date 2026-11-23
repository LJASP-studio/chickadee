---
description: tide-cli reads the national public tide table, whose format is fixed, after the harbour web page's layout broke the reader twice.
date: 2026-02-16
source: [tide-cli/docs/decisions.md, tide-cli/TODO.md]
code: [tide-cli/internal/forecast/]
tags: [decision]
---
# 2026-02-16 tide-cli reads a public tide table

[[tide-cli]] reads tide times from the national public tide table. It replaces [[2026-02-02 tide-cli reads the harbour web page]]: that page's layout changed twice in two weeks. Reading the table is still to do in [[forecast package]].

Related: [[tide-cli]] · [[Network access]]
