defmodule HelpfulOptions do
  @moduledoc """
  The command-line option parser
  """

  alias HelpfulOptions.{
    Errors,
    Logging,
    Other,
    OtherErrors,
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

  If you want to accept any supplied switches, use `:any`:

      iex> HelpfulOptions.parse(["--param", "value"], switches: :any)
      {:ok, %{param: "value"}, []}

    Note: using `:any` will not work for switches that do not exist as atoms.
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

    The third group of command-line arguments is other text.

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
  @type options :: [subcommands: Subcommands.t(), switches: Switches.t(), other: Other.t()]
  @spec parse(argv, Keyword.t()) :: {:ok, map, [String.t()]} | {:error, Errors.t()}
  def parse(args, options) do
    with {:ok, opts} <- options_map(options),
         {:ok, switches, other} <- Switches.parse(args, opts[:switches]),
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

  def help(switches) do
    items =
      switches
      |> Enum.map(&switch_help/1)
      |> Enum.join("\n")

    "Options:\n#{items}"
  end

  defp switch_help({name, options}) do
    left_column = if options.type == :string do
      parameter = name |> Atom.to_string() |> String.upcase()
      "  --#{name}=#{parameter}  "
    else
      "  --#{name}  "
    end
    extra = @help_left_column_width - String.length(left_column)
    padding = if extra > 0 do
      String.duplicate(" ", extra)
    else
      ""
    end
    right_column = if options[:description], do: [options.description], else: []
    right_column = if options[:required], do: ["Required" | right_column], else: right_column
    right_column = if length(right_column) == 0, do: ["Optional parameter"], else: right_column
    right_column = right_column |> Enum.reverse() |> Enum.join(". ")
    "#{left_column}#{padding}#{right_column}"
  end

  defp options_map(options), do: {:ok, Enum.into(options, %{})}
end
