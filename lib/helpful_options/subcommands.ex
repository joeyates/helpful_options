defmodule HelpfulOptions.Subcommands do
  @spec strip([String.t()]) :: {:ok, [String.t()], [String.t()]}
  @doc ~S"""
      iex> HelpfulOptions.Subcommands.strip(["foo", "bar", "--baz", "qux"])
      {:ok, ["foo", "bar"], ["--baz", "qux"]}
  """
  def strip(args) do
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
end
