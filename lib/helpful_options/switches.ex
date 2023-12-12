defmodule HelpfulOptions.Switches do
  alias HelpfulOptions.SwitchErrors

  @default_switches [
    help: %{type: :boolean, short: :h, description: "Show a help message"},
    quiet: %{type: :boolean, short: :q, description: "Suppress output"},
    verbose: %{type: :boolean, short: :v, description: "Increase verbosity"}
  ]

  @type t :: [{atom, switch}] | :any | nil
  @type switch :: %{
          required(:type) => switch_type,
          short: String.t() | atom,
          description: String.t(),
          required: boolean,
          default: term
        }
  @type switch_type ::
          :boolean | :count | :float | :floats | :integer | :integers | :string | :strings

  @parameterless_types ~w(boolean count)a
  @parameter_types ~w(float integer string)a
  @collection_types ~w(floats integers strings)a
  @types @parameterless_types ++ @parameter_types ++ @collection_types

  @spec parse([String.t()], Keyword.t() | :any | nil) ::
          {:ok, map, [String.t()]} | {:error, HelpfulOptions.SwitchErrors.t()}
  @doc ~S"""
  Switches that have not been specified are returned as an error:

      iex> HelpfulOptions.Switches.parse(["--bar", "hi"], foo: %{type: :string})
      {:error, %HelpfulOptions.SwitchErrors{unknown: ["--bar"]}}

  Switch parameters of the wrong type are returned as an error:

      iex> HelpfulOptions.Switches.parse(["--bar", "hi"], bar: %{type: :float})
      {:error, %HelpfulOptions.SwitchErrors{incorrect: [{"--bar", "hi"}]}}

  Invalid switch types are returned as an error:

      iex> HelpfulOptions.Switches.parse(["--bar", "hi"], bar: %{type: :invalid})
      {:error, %HelpfulOptions.SwitchErrors{invalid: [bar: {:invalid_type, :invalid}]}}

  `:default` and `:required` are incompatible

      iex> HelpfulOptions.Switches.parse([], [foo: %{type: :string, required: true, default: "ok"}])
      {:error, %HelpfulOptions.SwitchErrors{invalid: [foo: :required_and_default]}}

  ## Default switches

    `--help`, `--quiet` and `--verbose` are handled automatically.

    `--help` can be supplied without any configuration:

      iex> HelpfulOptions.Switches.parse(["--help"], nil)
      {:ok, %{help: true}, []}

    `--quiet` and `--verbose` have the side-effect of setting the Logger level.
    By default, it is set to `:info`, `--verbose` sets it to `:debug`,
    while `:quiet` sets it to `:none`.

      iex> HelpfulOptions.Switches.parse(["--quiet"], nil)
      {:ok, %{quiet: true}, []}
  """

  def parse(args, switches \\ nil) do
    with {:ok, parse_type, switches} <- from_supplied(switches),
         {:ok} <- validate(switches),
         {:ok, parsed, other} <- parse_switches(args, parse_type, switches),
         {:ok} <- check_required(parsed, switches),
         {:ok, with_defaults} <- set_defaults(parsed, switches) do
      {:ok, with_defaults, other}
    else
      {:error, errors} ->
        {:error, errors}
    end
  end

  defp from_supplied(supplied) do
    case supplied do
      nil ->
        {:strict, @default_switches}

      :any ->
        {:switches, []}

      switches ->
        {
          :strict,
          @default_switches
          |> Keyword.merge(switches)
        }
    end
    |> then(fn {type, switches} -> {:ok, type, switches} end)
  end

  defp validate(switches) when is_list(switches) do
    switches
    |> Enum.reduce(
      [],
      fn {name, options}, bad ->
        case validate_switch(options) do
          {:error, error} ->
            bad ++ [{name, error}]

          {:ok} ->
            bad
        end
      end
    )
    |> then(fn
      [] ->
        {:ok}

      bad ->
        {:error, %SwitchErrors{invalid: bad}}
    end)
  end

  defp validate_switch(%{type: type}) when type not in @types do
    {:error, {:invalid_type, type}}
  end

  defp validate_switch(%{required: true, default: _default}) do
    {:error, :required_and_default}
  end

  defp validate_switch(%{}), do: {:ok}

  defp parse_switches(args, parse_type, switches) do
    aliases = aliases(switches)
    name_and_type = name_and_type(switches)

    case OptionParser.parse(args, [{:aliases, aliases}, {parse_type, name_and_type}]) do
      {named_list, other, []} ->
        process_parsed(named_list, other, switches)

      {_named_list, _remaining, invalid} ->
        {:error, split_invalid(invalid)}
    end
  end

  defp aliases(switches) do
    switches
    |> Enum.map(fn
      {name, %{short: short}} ->
        {short, name}

      _switch ->
        nil
    end)
    |> Enum.filter(& &1)
    |> Enum.map(fn
      {short, name} when is_atom(short) ->
        {short, name}

      {short, name} ->
        {String.to_atom(short), name}
    end)
  end

  defp name_and_type(switches) do
    switches
    |> Enum.map(fn
      {name, %{:type => type}} when type in @collection_types ->
        {name, :keep}

      {name, %{type: type}} ->
        {name, type}
    end)
  end

  defp process_parsed(named_list, other, switches) do
    grouped =
      named_list
      |> group_repeatable(switches)

    case convert_grouped(grouped, switches) do
      {:ok, named} ->
        named
        |> Enum.into(%{})
        |> then(&{:ok, &1, other})

      {:error, errors} ->
        {:error, errors}
    end
  end

  defp group_repeatable(named_list, switches) do
    named_list
    |> Enum.reduce(
      %{},
      fn {name, value}, acc ->
        case switches[name] do
          nil ->
            value

          %{:type => type} when type in @collection_types ->
            list = acc[name] || []
            list ++ [value]

          _ ->
            value
        end
        |> then(&Map.put(acc, name, &1))
      end
    )
  end

  defp convert_grouped(named_list, switches) do
    named_list
    |> Enum.map(fn {name, value} ->
      case switches[name] do
        %{type: :floats} ->
          {name, convert_group(Float, value)}

        %{type: :integers} ->
          {name, convert_group(Integer, value)}

        _ ->
          {name, value}
      end
    end)
    |> then(fn list ->
      wrong =
        Enum.filter(list, fn
          {_name, {:error, _}} -> true
          _ -> false
        end)

      if length(wrong) == 0 do
        {:ok, list}
      else
        errors =
          wrong
          |> Enum.map(fn {name, {:error, message}} -> {name, message} end)
          |> Enum.into(%{})

        {:error, %SwitchErrors{incorrect: errors}}
      end
    end)
  end

  defp convert_group(module, texts) do
    texts
    |> Enum.reduce(
      {[], []},
      fn text, {good, bad} ->
        case module.parse(text) do
          {float, ""} ->
            {good ++ [float], bad}

          _ ->
            {good, bad ++ [text]}
        end
      end
    )
    |> then(fn
      {good, []} ->
        good

      {_bad, bad} ->
        {:error, %{type: module, values: bad}}
    end)
  end

  # OptionParser returns invalid switches in two ways:
  # * `{"--known", BAD_VALUE}`
  # * `{"--unknown", nil}`
  defp split_invalid(invalid) do
    invalid
    |> Enum.reduce(
      {[], []},
      fn
        {switch, nil}, {bad, unknown} ->
          {bad, unknown ++ [switch]}

        {switch, value}, {bad, unknown} ->
          {bad ++ [{switch, value}], unknown}
      end
    )
    |> then(fn
      {incorrect, []} ->
        %SwitchErrors{incorrect: incorrect}

      {[], unknown} ->
        %SwitchErrors{unknown: unknown}

      {incorrect, unknown} ->
        %SwitchErrors{incorrect: incorrect, unknown: unknown}
    end)
  end

  defp check_required(named, switches) do
    missing =
      switches
      |> Enum.map(fn
        {name, %{required: true}} ->
          if !Map.has_key?(named, name), do: name

        _ ->
          nil
      end)
      |> Enum.filter(& &1)

    if length(missing) == 0 do
      {:ok}
    else
      {:error, %SwitchErrors{missing: missing}}
    end
  end

  defp set_defaults(named, switches) do
    defaults = defaults(switches)

    defaults
    |> Enum.reduce(
      named,
      fn {key, default}, acc ->
        if Map.has_key?(acc, key) do
          acc
        else
          Map.put(acc, key, default)
        end
      end
    )
    |> then(&{:ok, &1})
  end

  defp defaults(switches) do
    switches
    |> Enum.map(fn
      {name, %{default: value}} ->
        {name, value}

      _switch ->
        nil
    end)
    |> Enum.filter(& &1)
    |> Enum.into(%{})
  end

  @help_left_column_width 31

  @spec help(t) :: {:ok, String.t()}
  @doc ~S"""
  Returns the help block related to switches

      iex> HelpfulOptions.Switches.help(foo: %{type: :string}, bar: %{type: :integer})
      {
        :ok,
        "-h, --help                     Show a help message\n" <>
        "-q, --quiet                    Suppress output\n" <>
        "-v, --verbose                  Increase verbosity\n" <>
        "  --foo=FOO                    Optional parameter\n" <>
        "  --bar=BAR                    Optional parameter"
      }

  Returns a generic test when `:any` is used:

      iex> HelpfulOptions.Switches.help(:any)
      {:ok, "Accepts any switch-type arguments"}

  By default, it returns an empty string:

      iex> HelpfulOptions.Switches.help(nil)
      {
        :ok,
        "-h, --help                     Show a help message\n" <>
        "-q, --quiet                    Suppress output\n" <>
        "-v, --verbose                  Increase verbosity"
      }
  """
  def help(switches) do
    with {:ok, parse_type, updated} <- from_supplied(switches),
         {:ok} <- validate(updated) do
      {:ok, do_help(switches, parse_type, updated)}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  defp do_help(:any, :switches, []), do: "Accepts any switch-type arguments"

  defp do_help(_, :strict, switches) do
    switches
    |> Enum.map(&switch_help/1)
    |> Enum.join("\n")
  end

  defp switch_help({name, options}) do
    parameter = name |> Atom.to_string() |> String.upcase()

    left_column =
      cond do
        options.type in @parameter_types and options[:short] ->
          "-#{options.short} #{parameter}, --#{name}=#{parameter}"

        options.type in @parameter_types ->
          "  --#{name}=#{parameter}"

        options[:short] ->
          "-#{options.short}, --#{name}"

        true ->
          "  --#{name}"
      end

    extra = @help_left_column_width - String.length(left_column)

    padding =
      if extra > 0 do
        String.duplicate(" ", extra)
      else
        ""
      end

    right_column = if options[:description], do: [options.description], else: []
    right_column = if options[:required], do: ["Required" | right_column], else: right_column
    right_column = if length(right_column) == 0, do: ["Optional parameter"], else: right_column

    right_column =
      if options[:default], do: ["Default: #{options.default}" | right_column], else: right_column

    right_column = right_column |> Enum.reverse() |> Enum.join(". ")
    "#{left_column}#{padding}#{right_column}"
  end
end
