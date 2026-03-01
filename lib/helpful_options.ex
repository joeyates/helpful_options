defmodule HelpfulOptions do
  @moduledoc """
  The command-line option parser
  """

  alias HelpfulOptions.{
    Errors,
    Logging,
    Other,
    OtherErrors,
    Subcommands,
    Switches,
    SwitchErrors
  }

  @doc ~S"""
  Parses command-line arguments, returns an error if
  required arguments are not supplied and sets the logging level

  Arguments are assumed to come in 1 or 2 groups:

  * switches like `--format json`,
  * other text.

  In the options, you can specify which switches and other text are acceptable.

  ## Switches

  Switches are specified as a list of atoms and maps:

  The `:type` key is required.

  There are to unary types:

  * `:boolean` - a switch that is either present or absent
  * `:count` - a switch that can be repeated, the value is the number of times it was repeated.

  Example:

      iex> ["--ok", "--plus", "--plus"]
      iex> |> HelpfulOptions.parse(switches: [ok: %{type: :boolean}, plus: %{type: :count}])
      {:ok, %{ok: true, plus: 2}, []}

  Boolean switches can be negated with `--no-`:

      iex> ["--no-ok"]
      iex> |> HelpfulOptions.parse(switches: [ok: %{type: :boolean}])
      {:ok, %{ok: false}, []}

  There are three types which specify their argument type:

  * `:float` - a switch that takes a floating-point value,
  * `:integer` - a switch that takes an integer value,
  * `:string` - a switch that takes a string value.

  Example:

      iex> ["--height", "2.54", "--minute", "59", "--foo", "hi"]
      iex> |> HelpfulOptions.parse(switches: [
      iex>   height: %{type: :float},
      iex>   minute: %{type: :integer},
      iex>   foo: %{type: :string}
      iex> ])
      {:ok, %{height: 2.54, minute: 59, foo: "hi"}, []}

  There are 3 'collection' types, which take multiple values:

  * `:strings` - the value is a list of strings,
  * `:integers` - the value is a list of integers,
  * `:floats` - the value is a list of floats.

  Example:

      iex> args = [
      iex>   "--word", "hi", "--word", "there",
      iex>   "--number", "42", "--number", "99",
      iex>   "--height", "1.1", "--height", "2.2"
      iex> ]
      iex> HelpfulOptions.parse(args, switches: [
      iex>   word: %{type: :strings},
      iex>   number: %{type: :integers},
      iex>   height: %{type: :floats}
      iex> ])
      {:ok, %{word: ["hi", "there"], number: [42, 99], height: [1.1, 2.2]}, []}

  Switches that have not been specified are returned as an error:

      iex> HelpfulOptions.parse(["--bar", "hi"], switches: [foo: %{type: :string}])
      {:error, %HelpfulOptions.Errors{switches: %HelpfulOptions.SwitchErrors{unknown: ["--bar"]}}}

  Switch parameters of the wrong type are returned as an error:

      iex> HelpfulOptions.parse(["--bar", "hi"], switches: [bar: %{type: :float}])
      {:error, %HelpfulOptions.Errors{switches: %HelpfulOptions.SwitchErrors{incorrect: [{"--bar", "hi"}]}}}

  If you want to accept any supplied switches, use `switches: :any`:

      iex> HelpfulOptions.parse(["--param", "value"], switches: :any)
      {:ok, %{param: "value"}, []}

    Note: using `switches: :any` will not work for switches that do not exist as atoms.
    [HelpfulOptions will not create new atoms for you](https://hexdocs.pm/elixir/OptionParser.html#parse/2-parsing-unknown-switches).

    You can specify a shortened name for a switch:

      iex> HelpfulOptions.parse(["-f", "hi"], switches: [foo: %{type: :string, short: :f}])
      {:ok, %{foo: "hi"}, []}

    Aliases can be strings or atoms:

      iex> ["--foo", "hi"]
      iex> |> HelpfulOptions.parse(switches: [foo: %{type: :string, short: "f"}])
      {:ok, %{foo: "hi"}, []}

  Switches can have default values:

      iex> HelpfulOptions.parse([], switches: [bar: %{type: :string, default: "Hello"}])
      {:ok, %{bar: "Hello"}, []}

  Switches which internally contain underscores, will be expected to contain dashes:

      iex> HelpfulOptions.parse(["--foo-bar", "hi"], switches: [foo_bar: %{type: :string}])
      {:ok, %{foo_bar: "hi"}, []}

  Supplying underscored switches with dashes will result in an error:

      iex> HelpfulOptions.parse(["--foo_bar", "hi"], switches: [foo_bar: %{type: :string}])
      {:error, %HelpfulOptions.Errors{switches: %HelpfulOptions.SwitchErrors{unknown: ["--foo_bar"]}}}

  ## Default switches

    `--help`, `--quiet` and `--verbose` are handled automatically.

    `--help` can be supplied without any configuration:

      iex> HelpfulOptions.parse(["--help"], [])
      {:ok, %{help: true}, []}

    `--quiet` and `--verbose` set the Logger level.
    By default, it is set to `:info`, `--verbose` sets it to `:debug`,
    while `:quiet` sets it to `:none`.

      iex> HelpfulOptions.parse(["--quiet"], [])
      {:ok, %{quiet: true}, []}

  ## Other

    The second group of command-line arguments is other text.

    You can specify how many other parameters are required:

      iex> HelpfulOptions.parse(["--", "first", "second"], other: 2)
      {:ok, %{}, ["first", "second"]}

    Note: to distinguish them from subcomands,
    other parameters must be preceded by `--`, or by switches.

    You can indicate limits with `:min` and/or `:max`:

      iex> HelpfulOptions.parse(["--", "first", "second"], other: %{min: 2, max: 3})
      {:ok, %{}, ["first", "second"]}

    Alternatively, you can accept any number of other parameters with `:any`:

      iex> HelpfulOptions.parse(["--", "first", "second"], other: :any)
      {:ok, %{}, ["first", "second"]}

    It's an error if you specify a count and the wrong number of other parameters is supplied:

      iex> HelpfulOptions.parse(["--", "first"], other: 2)
      {:error, %HelpfulOptions.Errors{other: %HelpfulOptions.OtherErrors{required: 2, actual: 1}}}

    It's also an error if other parameters are supplied when none were specified:

      iex> HelpfulOptions.parse(["--", "pizza"], [])
      {:error, %HelpfulOptions.Errors{other: %HelpfulOptions.OtherErrors{unexpected: ["pizza"]}}}

    Or, if they are outside the indicated range:

      iex> HelpfulOptions.parse(["--", "first"], other: %{min: 2, max: 3})
      {:error, %HelpfulOptions.Errors{other: %HelpfulOptions.OtherErrors{max: 3, min: 2, actual: 1}}}

    Switches and other parameters can, of course, be combined:

      iex> ["--foo", "hi", "bar"]
      iex> |> HelpfulOptions.parse(switches: [foo: %{type: :string}], other: 1)
      {:ok, %{foo: "hi"}, ["bar"]}
  """

  @type argv :: [String.t()]
  @type options :: [switches: Switches.t(), other: Other.t()]
  @spec parse(argv, options) :: {:ok, map, [String.t()]} | {:error, Errors.t()}
  def parse(argv, options) do
    with {:ok, opts} <- options_map(options),
         {:ok, switches, other} <- Switches.parse(argv, opts[:switches]),
         {:ok} <- Other.check(other, opts[:other]),
         {:ok} <- Logging.apply(switches) do
      {:ok, switches, other}
    else
      {:error, %SwitchErrors{} = errors} ->
        {:error, %Errors{switches: errors}}

      {:error, %OtherErrors{} = errors} ->
        {:error, %Errors{other: errors}}
    end
  end

  @doc ~S"""
      iex> HelpfulOptions.parse!(["--foo", "hi"], switches: [foo: %{type: :string}])
      {%{foo: "hi"}, []}

      iex> HelpfulOptions.parse!(["--bar", "hi"], switches: [foo: %{type: :string}])
      ** (ArgumentError) --bar - unknown switch
  """
  @spec parse!(argv, options) :: {map, [String.t()]}
  def parse!(argv, options) do
    case parse(argv, options) do
      {:ok, switches, other} ->
        {switches, other}

      {:error, errors} ->
        raise ArgumentError, to_string(errors)
    end
  end

  @doc ~S"""
  Parses command-line arguments against a list of command definitions.

  Uses `Subcommands.strip/1` to extract subcommands from argv, matches them
  against the definitions, and delegates to `parse/2` with the matched
  definition's `:switches` and `:other` config.

  Returns `{:ok, matched_commands, switches_map, other_args}` on success.

  ## Examples

  A simple command with switches:

      iex> definitions = [
      iex>   %{commands: ["remote", "add"], switches: [name: %{type: :string}]},
      iex>   %{commands: ["remote"], switches: [verbose: %{type: :boolean}]}
      iex> ]
      iex> HelpfulOptions.parse_commands(["remote", "add", "--name", "origin"], definitions)
      {:ok, ["remote", "add"], %{name: "origin"}, []}

  A root command (empty commands list) works like `parse/2`:

      iex> definitions = [
      iex>   %{commands: [], switches: [verbose: %{type: :boolean}]}
      iex> ]
      iex> HelpfulOptions.parse_commands(["--verbose"], definitions)
      {:ok, [], %{verbose: true}, []}

  An unknown command returns an error:

      iex> definitions = [
      iex>   %{commands: ["remote"], switches: nil}
      iex> ]
      iex> HelpfulOptions.parse_commands(["branch", "--verbose"], definitions)
      {:error, {:unknown_command, ["branch"]}}

  Returns 'other:' arguments as a list, and validates them according to the definition:

      iex> definitions = [
      iex>   %{commands: ["deploy"], switches: [env: %{type: :string}], other: 1}
      iex> ]
      iex> HelpfulOptions.parse_commands(["deploy", "--env", "prod", "myapp"], definitions)
      {:ok, ["deploy"], %{env: "prod"}, ["myapp"]}

  Returns `OtherErrors` when wrong number of other args is given:

      iex> definitions = [
      iex>   %{commands: ["deploy"], switches: nil, other: 2}
      iex> ]
      iex> HelpfulOptions.parse_commands(["deploy", "--", "one"], definitions)
      {:error, %HelpfulOptions.Errors{other: %HelpfulOptions.OtherErrors{required: 2, actual: 1}}}

  An atom as a placeholder entry matches any text token at that position:

      iex> definitions = [
      iex>   %{commands: ["remote", "add", :source]}
      iex> ]
      iex> HelpfulOptions.parse_commands(["remote", "add", "origin"], definitions)
      {:ok, ["remote", "add", "origin"], %{}, []}

  When both an exact and a placeholder definition could match, the exact one wins:

      iex> definitions = [
      iex>   %{commands: ["remote", "add"], switches: [name: %{type: :string}]},
      iex>   %{commands: ["remote", :any], switches: [name: %{type: :string}]}
      iex> ]
      iex> HelpfulOptions.parse_commands(["remote", "add", "--name", "origin"], definitions)
      {:ok, ["remote", "add"], %{name: "origin"}, []}

  When no definitions match, the error indicates the unknown command:

      iex> definitions = [
      iex>   %{commands: [:foo, "add"], switches: [name: %{type: :string}], other: nil}
      iex> ]
      iex> HelpfulOptions.parse_commands(["remote", "remove", "--name", "origin"], definitions)
      {:error, {:unknown_command, ["remote", "remove"]}}

  Duplicate command definitions return an error:

      iex> definitions = [
      iex>   %{commands: ["remote"], switches: nil},
      iex>   %{commands: ["remote"], switches: [verbose: %{type: :boolean}]}
      iex> ]
      iex> HelpfulOptions.parse_commands(["remote"], definitions)
      {:error, {:duplicate_commands, ["remote"]}}

  Parse errors are returned as-is:

      iex> definitions = [
      iex>   %{commands: ["run"], switches: [count: %{type: :integer}]}
      iex> ]
      iex> HelpfulOptions.parse_commands(["run", "--count", "abc"], definitions)
      {:error, %HelpfulOptions.Errors{switches: %HelpfulOptions.SwitchErrors{incorrect: [{"--count", "abc"}]}}}
  """
  @spec parse_commands(argv, [HelpfulOptions.CommandDefinition.t()]) ::
          {:ok, [String.t()], map, [String.t()]} | {:error, term}
  def parse_commands(argv, definitions) do
    with {:ok, subcommands, rest} <- Subcommands.strip(argv),
         sorted = sort_definitions(definitions),
         :ok <- check_duplicate_commands(sorted),
         {:ok, definition} <- find_definition(sorted, subcommands),
         options = [switches: definition[:switches], other: definition[:other]],
         {:ok, switches, other} <- parse(rest, options) do
      {:ok, subcommands, switches, other}
    end
  end

  defp sort_definitions(definitions) do
    Enum.sort_by(definitions, fn defn ->
      first_any = Enum.find_index(defn.commands, &is_atom/1) || length(defn.commands)
      {-length(defn.commands), -first_any}
    end)
  end

  defp find_definition(definitions, subcommands) do
    definitions
    |> Enum.find(fn definition -> commands_match?(definition.commands, subcommands) end)
    |> case do
      nil -> {:error, {:unknown_command, subcommands}}
      definition -> {:ok, definition}
    end
  end

  @doc ~S"""
  Bang variant of `parse_commands/2` that raises on error.

      iex> definitions = [
      iex>   %{commands: ["remote", "add"], switches: [name: %{type: :string}]}
      iex> ]
      iex> HelpfulOptions.parse_commands!(["remote", "add", "--name", "origin"], definitions)
      {["remote", "add"], %{name: "origin"}, []}

      iex> definitions = [
      iex>   %{commands: ["remote"], switches: nil}
      iex> ]
      iex> HelpfulOptions.parse_commands!(["branch"], definitions)
      ** (ArgumentError) unknown command: branch

      iex> definitions = [
      iex>   %{commands: ["remote"], switches: nil},
      iex>   %{commands: ["remote"], switches: nil}
      iex> ]
      iex> HelpfulOptions.parse_commands!(["remote"], definitions)
      ** (ArgumentError) duplicate commands: remote
  """
  @spec parse_commands!(argv, [HelpfulOptions.CommandDefinition.t()]) :: {[String.t()], map, [String.t()]}
  def parse_commands!(argv, definitions) do
    case parse_commands(argv, definitions) do
      {:ok, commands, switches, other} ->
        {commands, switches, other}

      {:error, {:unknown_command, commands}} ->
        raise ArgumentError, "unknown command: #{Enum.join(commands, " ")}"

      {:error, {:duplicate_commands, commands}} ->
        raise ArgumentError, "duplicate commands: #{Enum.join(commands, " ")}"

      {:error, errors} ->
        raise ArgumentError, to_string(errors)
    end
  end

  @spec help(options) :: {:ok, String.t()}
  @doc ~S"""
      iex> HelpfulOptions.help(switches: [foo: %{type: :string}])
      {
        :ok,
        "-h, --help                     Show a help message\n" <>
        "-q, --quiet                    Suppress output\n" <>
        "-v, --verbose                  Increase verbosity\n" <>
        "  --foo=FOO                    Optional parameter"
      }
  """
  def help(options) do
    Switches.help(options[:switches])
  end

  @spec help!(options) :: String.t()
  @doc ~S"""
      iex> HelpfulOptions.help!(switches: [foo: %{type: :string}])
      "-h, --help                     Show a help message\n" <>
      "-q, --quiet                    Suppress output\n" <>
      "-v, --verbose                  Increase verbosity\n" <>
      "  --foo=FOO                    Optional parameter"
  """
  def help!(options) do
    {:ok, help} = help(options)
    help
  end

  @spec help_commands(String.t(), [HelpfulOptions.CommandDefinition.t()]) :: {:ok, String.t()} | {:error, term}
  @doc ~S"""
  Generates formatted help text from a list of command definitions.

  Each definition is rendered as a subcommand heading followed by its switch list.
  Sections are separated by blank lines.

  A single command with switches:

      iex> HelpfulOptions.help_commands("my_program", [
      iex>   %{commands: ["remote", "add"], switches: [name: %{type: :string, description: "Remote name"}]}
      iex> ])
      {
        :ok,
        "my_program remote add\n" <>
        "-h, --help                     Show a help message\n" <>
        "-q, --quiet                    Suppress output\n" <>
        "-v, --verbose                  Increase verbosity\n" <>
        "  --name=NAME                  Remote name"
      }

  Multiple commands:

      iex> HelpfulOptions.help_commands("my_program", [
      iex>   %{commands: ["remote", "add"], switches: [name: %{type: :string, description: "Remote name"}]},
      iex>   %{commands: ["remote", "remove"], switches: [name: %{type: :string, description: "Remote name"}]}
      iex> ])
      {
        :ok,
        "my_program remote add\n" <>
        "-h, --help                     Show a help message\n" <>
        "-q, --quiet                    Suppress output\n" <>
        "-v, --verbose                  Increase verbosity\n" <>
        "  --name=NAME                  Remote name\n" <>
        "\n" <>
        "my_program remote remove\n" <>
        "-h, --help                     Show a help message\n" <>
        "-q, --quiet                    Suppress output\n" <>
        "-v, --verbose                  Increase verbosity\n" <>
        "  --name=NAME                  Remote name"
      }

  A placeholder atom in the command path is rendered as `<placeholder>`:

      iex> HelpfulOptions.help_commands("my_program", [
      iex>   %{commands: ["remote", :source], switches: [name: %{type: :string, description: "Remote name"}]}
      iex> ])
      {
        :ok,
        "my_program remote <source>\n" <>
        "-h, --help                     Show a help message\n" <>
        "-q, --quiet                    Suppress output\n" <>
        "-v, --verbose                  Increase verbosity\n" <>
        "  --name=NAME                  Remote name"
      }

  A root command (`commands: []`) is rendered with just the program name:

      iex> HelpfulOptions.help_commands("my_program", [
      iex>   %{commands: [], switches: [debug: %{type: :boolean, description: "Enable debug mode"}]}
      iex> ])
      {
        :ok,
        "my_program\n" <>
        "-h, --help                     Show a help message\n" <>
        "-q, --quiet                    Suppress output\n" <>
        "-v, --verbose                  Increase verbosity\n" <>
        "  --debug                      Enable debug mode"
      }
  """
  def help_commands(program, definitions) do
    result =
      definitions
      |> Enum.reduce_while([], fn definition, acc ->
        case Switches.help(definition[:switches]) do
          {:ok, switches_help} ->
            section = format_command_section(program, definition[:commands], switches_help)
            {:cont, [section | acc]}

          {:error, _} = error ->
            {:halt, error}
        end
      end)

    case result do
      {:error, _} = error -> error
      sections -> {:ok, sections |> Enum.reverse() |> Enum.join("\n\n")}
    end
  end

  @spec help_commands!(String.t(), [HelpfulOptions.CommandDefinition.t()]) :: String.t()
  @doc ~S"""
  Bang variant of `help_commands/2` that returns the help string directly or raises `ArgumentError`.

      iex> HelpfulOptions.help_commands!("my_program", [
      iex>   %{commands: ["remote", "add"], switches: [name: %{type: :string, description: "Remote name"}]}
      iex> ])
      "my_program remote add\n" <>
      "-h, --help                     Show a help message\n" <>
      "-q, --quiet                    Suppress output\n" <>
      "-v, --verbose                  Increase verbosity\n" <>
      "  --name=NAME                  Remote name"
  """
  def help_commands!(program, definitions) do
    case help_commands(program, definitions) do
      {:ok, help} -> help
      {:error, errors} -> raise ArgumentError, to_string(errors)
    end
  end

  defp format_command_section(program, [], switches_help) do
    "#{program}\n#{switches_help}"
  end

  defp format_command_section(program, commands, switches_help) do
    heading =
      commands
      |> Enum.map(fn
        placeholder when is_atom(placeholder) -> "<#{placeholder}>"
        cmd -> cmd
      end)
      |> Enum.join(" ")

    "#{program} #{heading}\n#{switches_help}"
  end

  defp options_map(options), do: {:ok, Enum.into(options, %{})}

  defp commands_match?(patterns, commands) do
    length(patterns) == length(commands) and
      patterns
      |> Enum.zip(commands)
      |> Enum.all?(fn
        {p, _c} when is_atom(p) -> true
        {p, c} -> p == c
      end)
  end

  defp check_duplicate_commands(sorted_definitions) do
    sorted_definitions
    |> Enum.group_by(& &1.commands)
    |> Enum.find(fn {_commands, defs} -> length(defs) > 1 end)
    |> case do
      nil -> :ok
      {commands, _} -> {:error, {:duplicate_commands, commands}}
    end
  end
end
