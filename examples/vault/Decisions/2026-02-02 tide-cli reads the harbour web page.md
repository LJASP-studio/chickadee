---
description: "Superseded by 2026-02-16 tide-cli reads a public tide table: tide times were read off the harbour's web page, no key, no extra source."
date: 2026-02-02
source: tide-cli/docs/decisions.md
code: [tide-cli/internal/forecast/forecast.go]
tags: [decision]
status: superseded
superseded_by: "[[2026-02-16 tide-cli reads a public tide table]]"
---
# 2026-02-02 tide-cli reads the harbour web page

The first plan for [[tide-cli]] was to read the day's tides from the harbour's own web page, which needed no API key. The page's layout changed twice in two weeks, so [[2026-02-16 tide-cli reads a public tide table]] replaced this.

Related: [[tide-cli]] · [[forecast package]]
