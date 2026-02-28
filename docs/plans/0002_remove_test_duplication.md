---
title: Remove Duplicate Tests
description: Remove duplicate tests, preferring doctests
branch: feature/remove-duplicate-tests
---

# Overview

Several normal tests in `test/helpful_options/parse_commands_test.exs` duplicate doctests already defined in `lib/helpful_options.ex` for `parse_commands/2` and `parse_commands!/2`. Since both are run (via `doctest HelpfulOptions` in `helpful_options_test.exs`), the duplicate normal tests should be removed to prefer the doctests.

# Technical Specifics

**`parse_commands/2` — 5 duplicated normal tests to remove:**

- "most specific (longest) command match wins" — duplicates doctest at `lib/helpful_options.ex` L245–L250
- "matches root command with empty commands list" — duplicates doctest at L254–L258
- "returns unknown_command when no definition matches" — duplicates doctest at L262–L266
- "returns duplicate_commands error when definitions share the same commands" — duplicates doctest at L270–L275
- "propagates parse errors from parse/2" — duplicates doctest at L279–L283

**`parse_commands!/2` — 3 duplicated normal tests to remove:**

- "returns tuple on success" — duplicates doctest at L314–L318
- "raises ArgumentError on unknown command" — duplicates doctest at L320–L324
- "raises ArgumentError on duplicate commands" — duplicates doctest at L326–L331

**Unique normal tests to keep (no doctest equivalent):**

- "returns unknown_command with empty subcommands when no root definition exists"
- "handles other arguments correctly"
- "returns other error when wrong number of other args"
- "with no subcommands and no arguments"
- "raises on parse error" (`parse_commands!`)
