# HelpfulOptions

Processes command-line parameters.

Provides

* rich parameter declaration,
* formatted error messages,
* automatic logging setup,
* formatted parameter descriptions for `--help`.

It is intended for use with Mix tasks,
Bakeware and other systems for creating Elixir
command-line programs.

# Approach

This library assumes that the parameters that you want to process
are ordered as follows:

```sh
SUBCOMMAND --switch PARAMETER OTHER
```

With each part being repeatable and optional.

A Git example

```sh
git remote add -t feature -b main git@example.com:foo/bar
    __________ __________________ _______________________
        ^               ^                   ^
        |               |                   |
    subcommands      switches             other
```

Subcommands, like Git's `remote` can be one or more words.
Switches are `--key value` pairs.
Other parameters are positional arguments that follow the switches.

This library provides two main functions:

* `HelpfulOptions.parse/2` — for simple CLIs that only receive switches
  (and optional positional arguments).
* `HelpfulOptions.parse_commands/2` — for CLIs that accept commands
  and subcommands, each with their own switches and other parameters.

# Usage

## Simple CLI with `parse/2`

Use `parse/2` when your program does not have subcommands — it only
receives switches and, optionally, positional ("other") arguments.

```elixir
switches = [
  foo: %{type: :string, required: true},
  dry_run: %{type: :boolean},
  bar: %{type: :string, required: true}
]

case HelpfulOptions.parse(System.argv(), switches: switches, other: 1) do
  {:ok, parameters, [url]} ->
    MyApp.add_remote(parameters, url)
    0
  {:error, error} ->
    IO.puts(:stderr, error)
    1
end
```

## CLI with commands via `parse_commands/2`

Use `parse_commands/2` when your program handles multiple commands
(and, optionally, subcommands), each with its own set of switches
and other parameters — similar to tools like `git`, `mix`, or `docker`.

You provide a list of command definitions. Each definition specifies
the command words to match, the expected switches and other parameters:

```elixir
definitions = [
  %{commands: ["remote", "add"], switches: [name: %{type: :string, required: true}], other: 1},
  %{commands: ["remote"], switches: [verbose: %{type: :boolean}], other: nil},
  %{commands: ["status"], switches: [short: %{type: :boolean}], other: nil},
  %{commands: [], switches: [version: %{type: :boolean}], other: nil}
]

case HelpfulOptions.parse_commands(System.argv(), definitions) do
  {:ok, ["remote", "add"], switches, [url]} ->
    MyApp.add_remote(switches.name, url)
  {:ok, ["remote"], switches, _other} ->
    MyApp.list_remotes(switches)
  {:ok, ["status"], switches, _other} ->
    MyApp.show_status(switches)
  {:ok, [], switches, _other} ->
    if switches[:version], do: MyApp.print_version()
  {:error, {:unknown_command, commands}} ->
    IO.puts(:stderr, "Unknown command: #{Enum.join(commands, " ")}")
  {:error, error} ->
    IO.puts(:stderr, to_string(error))
end
```

Definitions are matched longest-first, so `["remote", "add"]` is
tried before `["remote"]`. An empty commands list (`[]`) matches
when no subcommand is given.

## `switches`

Underscores `_` in switches are replaced by hyphens `-`.

So, `:dry_run` is actually the command-line parameter `--dry-run`.

Three switches are added by the library:

```elixir
  [
    ...
    help: %{type: :boolean},
    verbose: %{type: :count},
    quiet: %{type: :boolean}
  ]
```

See the doc tests in `HelpfulOptions` for more examples.

## Installation

The package can be installed by adding `helpful_options`
to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:helpful_options, "~> 0.3"}
  ]
end
```
