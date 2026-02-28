---
title: Add Command/Subcommand Parsing Support
description: Implement `HelpfulOptions.parse_commands/2`
branch: feature/add-parse-commands
---

# Overview

Implement `HelpfulOptions.parse_commands/2` — a higher-level function that
accepts a list of command definitions, uses `Subcommands.strip/1` to extract
subcommands from argv, matches them against the definitions, and delegates to
`parse/2` with the matched definition's `:switches` and `:other` config.

## Signature

```elixir
@spec parse_commands(argv, [command_definition]) ::
  {:ok, [String.t()], map, [String.t()]} | {:error, term}

@type command_definition :: %{
  commands: [String.t()],   # subcommands to match (can be empty for the "root" command)
  switches: Switches.t(),   # same format as parse/2's switches option
  other: Other.t()          # same format as parse/2's other option
}
```

## Behaviour

1. Call `Subcommands.strip(argv)` to split argv into `{:ok, subcommands, rest}`.
   - e.g. `["remote", "add", "--verbose", "origin"]` →
     subcommands: `["remote", "add"]`, rest: `["--verbose", "origin"]`
2. Sort the supplied command definitions by `:commands` list length (longest
   first) so the most specific definition is tried first.
3. Return `{:error, {:duplicate_commands, commands_list}}` if two or more
   definitions share the same `:commands` list.
4. Find the command definition whose `:commands` list exactly matches the
   extracted subcommands.
5. Pass `rest` to `HelpfulOptions.parse/2` using the matched definition's
   `:switches` and `:other`.
6. On success, return `{:ok, matched_commands, switches_map, other_args}`.
7. On no match, return `{:error, {:unknown_command, subcommands}}`.
8. On parse error, return the error from `parse/2` as-is.

Also implement a bang variant `parse_commands!/2` that raises on error.

## Where to add code

- New public functions `parse_commands/2` and `parse_commands!/2` in
  `lib/helpful_options.ex`, after the existing `parse!/2`.
- Add `Subcommands` to the existing alias block in `HelpfulOptions`.
- Doctests on the new functions (preferred over separate test cases where
  possible, per project convention).
- A new test file `test/helpful_options/parse_commands_test.exs` for edge
  cases not easily expressed as doctests.

## Tasks

- [x] Add `Subcommands` alias and implement `parse_commands/2` with doctests
- [x] Implement `parse_commands!/2` with doctests
- [x] Add test file for edge-case tests (multiple definitions, no match, parse errors)
- [x] Ensure all existing tests still pass
