defmodule HelpfulOptions.Subcommands do
  @type t :: [[String.t()]] | :any

  alias HelpfulOptions.SubcommandErrors

  @spec parse([String.t()], [[String.t()]] | :any | nil) ::
          {:ok, [String.t()], [String.t()]} | {:error, HelpfulOptions.SubcommandsErrors.t()}
  @doc ~S"""
  Subcommands are specified as a list of lists of strings:

      iex> ["some", "subcommand"]
      iex> |> HelpfulOptions.Subcommands.parse([~w(other), ~w(some subcommand)])
      {:ok, ["some", "subcommand"], []}

  Everything else, from the first parameter beginning with a hyphen is returned in a second list:

      iex> ["some", "subcommand", "--other"]
      iex> |> HelpfulOptions.Subcommands.parse([~w(some subcommand)])
      {:ok, ["some", "subcommand"], ["--other"]}

  `help` is accepted by default:

      iex> HelpfulOptions.Subcommands.parse(["help"])
      {:ok, ["help"], []}

  Unexpected subcommands are an error:

      iex> ["foo", "bar"]
      iex> |> HelpfulOptions.Subcommands.parse(subcommands: [~w(other), ~w(some subcommand)])
      {:error, %HelpfulOptions.SubcommandErrors{unknown: ["foo", "bar"]}}

  Alternatively, you can specify `:any`:

      iex> HelpfulOptions.Subcommands.parse(["any", "text"], :any)
      {:ok, ["any", "text"], []}
  """
  def parse(args, acceptable \\ nil) do
    help = if Enum.member?(args, "help"), do: ["help"], else: []
    args = Enum.reject(args, &(&1 == "help"))
    with {:ok, subcommands, rest} <- extract(args),
         {:ok} <- check(subcommands, acceptable) do
      {:ok, help ++ subcommands, rest}
    else
      {:error, errors} -> {:error, errors}
    end
  end

  defp extract(args) do
    args
    |> Enum.reduce(
      {[], []},
      fn
        "-" <> _rest = arg, {subcommands, rest} ->
          # When we find a dashed argument, we're done with subcommands
          {subcommands, rest ++ [arg]}

        arg, {subcommands, []} ->
          # If we haven't found a dashed argument, we're still in subcommand territory
          {subcommands ++ [arg], []}

        arg, {subcommands, rest} ->
          # We've found a dashed argument, so everything else is a parameter
          {subcommands, rest ++ [arg]}
      end
    )
    |> then(fn {subommands, rest} -> {:ok, subommands, rest} end)
  end

  defp check([], _acceptable), do: {:ok}

  defp check(_subcommands, :any), do: {:ok}

  defp check(subcommands, nil) do
    {:error, %SubcommandErrors{unexpected: subcommands}}
  end

  defp check(subcommands, acceptable) do
    acceptable = acceptable || []

    found = Enum.member?(acceptable, subcommands)

    if found do
      {:ok}
    else
      {:error, %SubcommandErrors{unknown: subcommands}}
    end
  end
end
