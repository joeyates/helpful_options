defmodule HelpfulOptions.Errors do
  @moduledoc """
  Represents an error that occurred while parsing options.
  """
  alias HelpfulOptions.{SwitchErrors, OtherErrors}

  @type t :: %__MODULE__{
          switches: SwitchErrors.t(),
          other: OtherErrors.t()
        }
  defstruct ~w(switches other)a

  defimpl String.Chars do
    @spec to_string(HelpfulOptions.Errors.t()) :: String.t()
    def to_string(errors) do
      [errors.switches, errors.other]
      |> Enum.map(&Kernel.to_string/1)
      |> Enum.filter(&(&1 != ""))
      |> Enum.join("\n")
    end
  end
end
