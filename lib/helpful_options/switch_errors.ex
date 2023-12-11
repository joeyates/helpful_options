defmodule HelpfulOptions.SwitchErrors do
  @type t :: %__MODULE__{
          invalid: Keyword.t(),
          missing: [atom],
          incorrect: [%{type: atom, values: [String.t()]}],
          unknown: [String.t()]
        }
  defstruct ~w(missing incorrect invalid unknown)a
end
