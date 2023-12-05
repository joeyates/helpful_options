# HelpfulOptions

A wrapper for the standard library's OptionParser.

It adds

* automatic logging setup,
* option summary output for `--help`

# Usage

Define some switches:

```elixir
def MyCLIModule do
  @switches [
    foo: %{type: :string, required: true},
    dry_run: %{type: :boolean},
    bar: %{type: :string, required: true}
  ]

  ...
```

Two switches are added by the library:

```elixir
    verbose: %{type: :count},
    quiet: %{type: boolean}
```

The, parse your command-line arguments:

```elixir
  def run(args) do
    case HelpfulOption.run(args, switches: @switches) do
      {:ok, options, arguments} ->
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

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `helpful_options` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:helpful_options, "~> 0.1.0"}
  ]
end
```