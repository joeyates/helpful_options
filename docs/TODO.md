# Add Command/Subcommand Parsing Support

Status: [x]

## Description

Implement a higher-level `parse_commands/2` function that automatically matches commands based on their subcommands and applies the appropriate switches and other parameter configurations.

This would simplify handling multi-command CLIs (like Git) by defining all command configurations upfront and delegating the subcommand matching and parsing to the library.

## Technical Specifics

- Implement `HelpfulOptions.parse_commands/2` with signature:
  ```elixir
  parse_commands(argv, command_definitions)
  ```
- First parameter: `argv` - the argument list to parse
- Second parameter: a list of command definition maps:
  ```elixir
  [
    %{
      commands: [string1, string2, ...],  # list of subcommands to match (can be empty)
      switches: switches_map,              # same format as parse/2
      other: count                         # same format as parse/2
    },
    ...
  ]
  ```
- Function should:
  1. Use `HelpfulOptions.Subcommands.strip/1` to extract subcommands from argv
  2. Match the extracted subcommands against each command definition's `:commands` list
  3. Apply the matched command's `:switches` and `:other` configuration
  4. Call `HelpfulOptions.parse/2` with the appropriate parameters
  5. Return `{:ok, matched_commands_list, parameters, other_args}` or `{:error, reason}`
     - Example: `{:ok, ["remote", "add"], %{foo: "bar"}, ["url"]}`
- Handle edge case: No matching command found

---

# Fix Typos in mix.exs and README

Status: [x]

## Description

Fix several typos across key project files that affect the project's presentation.

## Technical Specifics

- `mix.exs` line 12: `"otptions"` → `"options"` in the project description
- `README.md` line 10: `"paremeter"` → `"parameter"`
- `README.md` line 30: `"libarary"` → `"library"`

---

# Fix Broken Link and Outdated Version in README

Status: [ ]

## Description

The README has a broken markdown link and an outdated install version.

## Technical Specifics

- `README.md` line 72: `[lib/helpful_options.ex]` is a bare reference with no link target. Replace with an ExDoc module reference like `` `HelpfulOptions` `` (which auto-links on HexDocs) or an explicit link to the module docs page.
- `README.md` line 82: Installation version `~> 0.1.0` should be updated to `~> 0.3`.

---

# Add @moduledoc to All Public Modules

Status: [ ]

## Description

Most modules are missing `@moduledoc`, which means ExDoc shows them with no description on the documentation site.

## Technical Specifics

- Modules missing `@moduledoc`: `Switches`, `Subcommands`, `Other`, `OtherErrors`, `SwitchErrors`, `Logging`
- Only `HelpfulOptions` and `HelpfulOptions.Errors` currently have `@moduledoc`

---

# Improve ExDoc Configuration

Status: [ ]

## Description

Enhance the generated documentation site with better organization and metadata.

## Technical Specifics

- Add `groups_for_modules` to `mix.exs` docs config (e.g., group error structs separately from core modules)
- Add a `CHANGELOG.md` file and include it in the `extras` list
- Add `source_url` to docs config to enable "Edit on GitHub" links
- Consider adding a `logo` to docs config
