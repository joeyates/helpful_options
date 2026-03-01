---
title: Add `help_commands/1` for `parse_commands/2` Definitions
description: Add `HelpfulOptions.help_commands/1` and `help_commands!/1` to generate formatted help text from a list of command definitions.
branch: feature/add-help-commands
---

## Overview

`help/1` generates help text for the switches accepted by `parse/2`. This feature adds the parallel `help_commands/1` for `parse_commands/2`: given a list of command definitions it produces a formatted string with one section per definition, each showing the subcommand path followed by its switches (using the existing `Switches.help/1` logic).

## Tasks

- [ ] Add `HelpfulOptions.help_commands/1` — iterate definitions, format each as a subcommand heading + switch list via `Switches.help/1`
- [ ] Render `:any` wildcards in command paths as `<command>`
- [ ] Render `commands: []` (root command) without a subcommand prefix
- [ ] Add `HelpfulOptions.help_commands!/1` bang variant
- [ ] Add doctests covering: a single command with switches, multiple commands, and a root (`commands: []`) definition
- [ ] Address any additional implementation details that arise during development
- [ ] Mark the plan as "done"

## Principal Files

- `lib/helpful_options.ex` — new public functions added here
- `lib/helpful_options/switches.ex` — `Switches.help/1` reused internally

## Acceptance Criteria

- `HelpfulOptions.help_commands/1` returns `{:ok, string}` where each definition is represented as a subcommand heading (e.g. `remote add`) followed by its formatted switch list
- `:any` entries in command paths render as `<command>`
- `commands: []` definitions render without a subcommand prefix line
- `help_commands!/1` returns the string directly or raises `ArgumentError`
- All doctests pass
