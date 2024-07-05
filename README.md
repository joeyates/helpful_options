# HelpfulOptions

Processes command-line parameters.

Provides

* rich parameter declaration,
* formatted error messages,
* automatic logging setup,
* formatted paremeter descriptions for `--help`.

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
You probably want to handle each subcommand with its own block of code,
with its own switches.

This libarary's main function is `HelpfulOptions.parse/2`:

`parse/2` does **not** process subcommands.
It assumes you have stripped them off.
See `HelpfulOptions.Subcommands.strip/1`.

# Usage

```elixir
@switches: [
  foo: %{type: :string, required: true},
  dry_run: %{type: :boolean},
  bar: %{type: :string, required: true}
]

HelpfulOptions.parse(System.argv(), switches: @switches, other: 1) do
  {:ok, switches, [url]} ->
    MyApp.add_remote(switches, url)
    0
  {:error, error} ->
    IO.puts(:stderr, error)
    1
end
```

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

See the doc tests in [lib/helpful_options.ex] for more examples.

## Installation

The package can be installed by adding `helpful_options`
to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:helpful_options, "~> 0.1.0"}
  ]
end
```
