defmodule HelpfulOptions do
  @moduledoc """
  A project-specific command-line option parser
  """

  require Logger

  @help_left_column_width 29

  @doc ~S"""
  Parses command arguments, returns an error if
  required arguments are not supplied and sets the logging level

    iex> HelpfulOptions.run(["--foo", "hi"], switches: [foo: %{type: :string}])
    {:ok, %{foo: "hi"}, []}

    iex> HelpfulOptions.run(["-f", "hi"], switches: [foo: %{type: :string}], aliases: [f: :foo])
    {:ok, %{foo: "hi"}, []}

    iex> HelpfulOptions.run(["--bar", "hi"], switches: [foo: %{type: :string}])
    {:error, "Unexpected parameters supplied: [\"--bar\"]"}

    iex> HelpfulOptions.run(["non-switch"], remaining: 1)
    {:ok, %{}, ["non-switch"]}

    iex> HelpfulOptions.run(["pizza"])
    {:error, "You supplied unexpected non-switch arguments [\"pizza\"]"}

    iex> HelpfulOptions.run(["first", "second"], remaining: 2..3)
    {:ok, %{}, ["first", "second"]}

    iex> HelpfulOptions.run(["first"], remaining: 2)
    {:error, "Supply 2 non-switch arguments"}

    iex> HelpfulOptions.run(["first"], remaining: 2..3)
    {:error, "Supply 2..3 non-switch arguments"}

    iex> HelpfulOptions.help([foo: %{type: :boolean}])
    "Options:\n  --foo                      Optional parameter"

    iex> HelpfulOptions.help([foo: %{type: :string}])
    "Options:\n  --foo=FOO                  Optional parameter"

    iex> HelpfulOptions.help([foo: %{type: :string, required: true}])
    "Options:\n  --foo=FOO                  Required"

    iex> HelpfulOptions.help([foo: %{type: :boolean, description: "Frobnicate"}])
    "Options:\n  --foo                      Frobnicate"

    iex> HelpfulOptions.help([foo: %{type: :string, description: "Frobnicate"}])
    "Options:\n  --foo=FOO                  Frobnicate"

    iex> HelpfulOptions.help([foo: %{type: :string, description: "Frobnicate", required: true}])
    "Options:\n  --foo=FOO                  Frobnicate. Required"
  """
  def run(args, options \\ []) do
    with {:ok, opts} <- options_map(options),
         {:ok, named, remaining} <- parse(args, opts),
         {:ok} <- check_required(named, opts),
         {:ok} <- check_remaining(remaining, opts),
         {:ok} <- setup_logger(named),
         {:ok, filtered} <- remove_logging(named) do
      {:ok, filtered, remaining}
    else
      {:error, message} ->
        {:error, message}
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

  defp parse(args, opts) do
    aliases = (opts[:aliases] || []) ++ [q: :quiet, v: :verbose]
    switches = Keyword.merge((opts[:switches] || []), [quiet: %{type: :boolean}, verbose: %{type: :count}])
    switches_keyword = switches_keyword(switches)

    case OptionParser.parse(args, aliases: aliases, strict: switches_keyword) do
      {named_list, remaining, []} ->
        named = Enum.into(named_list, %{})
        {:ok, named, remaining}
      {_, _, invalid} ->
        keys = Enum.map(invalid, fn {key, _value} -> key end)
        {:error, "Unexpected parameters supplied: #{inspect(keys)}"}
    end
  end

  defp switches_keyword(switches) do
    Enum.map(switches, fn {name, %{type: type}} -> {name, type} end)
  end

  defp check_required(named, opts) do
    missing =
      (opts[:switches] || [])
      |> Enum.map(fn
          {name, %{required: true}} ->
            if !Map.has_key?(named, name), do: name
          _ ->
            nil
        end)
      |> Enum.filter(&(&1))

    if length(missing) == 0 do
      {:ok}
    else
      {:error, "Please supply the following parameters: #{inspect(missing)}"}
    end
  end

  defp check_remaining(remaining, %{remaining: %Range{} = range}) do
    if length(remaining) in range do
      {:ok}
    else
      {:error, "Supply #{inspect(range)} non-switch arguments"}
    end
  end

  defp check_remaining(remaining, %{remaining: count})
  when length(remaining) == count, do: {:ok}

  defp check_remaining(_remaining, %{remaining: count}) do
    {:error, "Supply #{count} non-switch arguments"}
  end

  defp check_remaining([], _options), do: {:ok}

  defp check_remaining(remaining, _opts) do
    {:error, "You supplied unexpected non-switch arguments #{inspect(remaining)}"}
  end

  defp setup_logger(named) do
    verbose = Map.get(named, :verbose, 1)
    quiet = Map.get(named, :quiet, false)

    level = if quiet do
      0
    else
      1 + verbose
    end
    level_atom =
      case level do
        0 -> :none
        1 -> :info
        _ -> :debug
      end
    Logger.configure([level: level_atom])
    Logger.debug("Logger level set to #{level_atom}")

    {:ok}
  end

  defp remove_logging(named) do
    {
      :ok,
      named
      |> Map.delete(:quiet)
      |> Map.delete(:verbose)
    }
  end
end
