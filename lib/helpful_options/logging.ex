defmodule HelpfulOptions.Logging do
  require Logger

  @spec apply(map()) :: {:ok}
  def apply(switches) do
    verbose = Map.get(switches, :verbose, 0)
    quiet = Map.get(switches, :quiet, false)

    level =
      cond do
        quiet ->
          0

        verbose ->
          2

        true ->
          1
      end

    level_atom =
      case level do
        0 -> :none
        1 -> :info
        _ -> :debug
      end

    Logger.configure(level: level_atom)
    Logger.debug("Logger level set to #{level_atom}")

    {:ok}
  end
end
