# HelpfulOptions

A wrapper for the standard library's OptionParser.

It adds

* an enriched parameter declaration,
* formatted error messages,
* automatic logging setup,
* option summary output for `--help`

This library assumes that the parameters that you want to process
will be ordered as follows:

```sh
YOUR_PROGRAM POSSIBLY SUBCOMMANDS --some dashed --arguments MAYBE OTHER STUFF
```

For this reason, it returns 3 things:

```
{SUBCOMMANDS, OPTIONS, OTHER}
```

* SUBCOMMANDS - a List of Strings,
* OPTIONS - a Map,
* OTHER - a List of Strings.

If you don't have subcommands or options
and want to force everything into `OTHER`, use `--`:

```sh
YOUR_PROGRAM -- OTHER STUFF
```

# Usage

Here are some example options:

```elixir
  options = [
    subcommands: [
      ~w(foo),
      ~w(foo bar)
    ],
    switches: [
      foo: %{type: :string, required: true},
      dry_run: %{type: :boolean},
      bar: %{type: :string, required: true}
    ]
  ]
```

All the keys are optional.

## `subcommands`

You can do one of two things:

* use `subcommands: :any`
* list all possible sequences (as in the example above).

The library treats `help` as a subcommand in a special way:

`help` doesn't need to be declared.
If found, it is **not** returned in the subcommand List,
instead, `%{help: true}` is returned as part of the options.

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

Then parse your command-line arguments:

```elixir
  def run(args) do
    case HelpfulOptions.run(args, switches: @switches) do
      {:ok, subcommands, options, arguments} ->
        ...
        0
      {:error, message} ->
        IO.puts :stderr, message
        1
    end
  end
end
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
