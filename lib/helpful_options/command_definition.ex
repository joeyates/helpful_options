defmodule HelpfulOptions.CommandDefinition do
  @moduledoc """
  Defines the structure of a command definition, which includes the expected commands, switches, and other parameters.
  """

  @type t :: %{
          description: String.t() | nil,
          commands: [String.t() | :any],
          switches: Switches.t(),
          other: Other.t()
        }
end
