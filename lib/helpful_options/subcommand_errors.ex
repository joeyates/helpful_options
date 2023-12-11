defmodule HelpfulOptions.SubcommandErrors do
  @type t :: %__MODULE__{
          unexpected: [String.t()],
          unknown: [String.t()]
        }
  defstruct ~w(unexpected unknown)a
end
