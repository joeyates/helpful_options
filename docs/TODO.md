# Add Command/Subcommand Parsing Support

Status: [ ]

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
