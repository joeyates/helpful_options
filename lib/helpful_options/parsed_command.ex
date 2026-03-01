defmodule HelpfulOptions.ParsedCommand do
  @moduledoc """
  Struct representing a parsed command from command-line arguments.
  """

  defstruct commands: [], switches: %{}, other: [] 

  @type t :: %__MODULE__{
          commands: [String.t() | atom()],
          switches: %{atom() => any()},
          other: [String.t()]
        }
end