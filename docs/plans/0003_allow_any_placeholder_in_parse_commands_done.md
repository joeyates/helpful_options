---
title: Allow `:any` Placeholder in `parse_commands/2` Commands List
description: Support `:any` as a wildcard atom in a command definition's `commands` list, matching any single subcommand token.
branch: feature/any-placeholder-in-parse-commands
---

## Overview

Extend `parse_commands/2` so that a command definition's `:commands` list may
contain the atom `:any` as a wildcard for a single positional subcommand.
For example, `%{commands: [:any, "add"], ...}` would match `["remote", "add"]`,
`["local", "add"]`, etc.

Exact-string entries in a definition have higher specificity than `:any` entries
of the same length, so `["remote", "add"]` is preferred over `[:any, "add"]`
when both would match.

## Tasks

- [x] Update `@type command_definition` so `commands` is typed as `[String.t() | :any]`
- [x] Add a private `commands_match?/2` predicate that compares two same-length
      lists element-wise, treating `:any` as matching any string
- [x] Replace the `defn.commands == subcommands` equality check in `parse_commands/2`
      with `commands_match?(defn.commands, subcommands)`
- [x] Update the sort in `parse_commands/2` to sort by length descending, then
      by specificity descending (position of the first `:any` entry descending —
      a wildcard appearing later in the list is more specific than one appearing
      earlier) so exact definitions are preferred over wildcard ones of the same
      length
- [x] Update `check_duplicate_commands/1` to group by a normalised key rather
      than the raw `commands` list, so two definitions that would always match
      the same inputs (e.g. `[:any]` and `[:any]`) are still flagged as
      duplicates
- [x] Add doctests to `parse_commands/2` illustrating `:any` usage
- [x] Add unit tests in `parse_commands_test.exs` covering:
      - `[:any]` matching a single arbitrary subcommand
      - `[:any, "add"]` matching `["remote", "add"]` but not `["remote", "remove"]`
      - exact definition preferred over `:any` definition of equal length
      - duplicate `:any` definitions detected and returned as an error
- [x] Address any additional implementation details that arise during development
- [x] Mark the plan as "done"

## Principal Files

- [lib/helpful_options.ex](../../lib/helpful_options.ex)
- [test/helpful_options/parse_commands_test.exs](../../test/helpful_options/parse_commands_test.exs)

## Acceptance Criteria

- `parse_commands/2` accepts `:any` atoms inside a definition's `:commands` list
- `:any` matches any single string subcommand token at that position
- A definition with all concrete strings is preferred over one with `:any` at the same length
- Duplicate wildcard definitions are still detected and return `{:error, {:duplicate_commands, ...}}`
- All existing tests and doctests continue to pass
