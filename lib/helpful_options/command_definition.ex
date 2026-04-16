defmodule HelpfulOptions.CommandDefinition do
  @moduledoc """
  Defines the structure of a command definition, which includes the expected commands, switches, and other parameters.
  """

  @type t :: %{
          :description => String.t() | nil,
          :commands => [String.t() | :any | atom()],
          optional(:switches) => Switches.t(),
          optional(:other) => Other.t()
        }
end
