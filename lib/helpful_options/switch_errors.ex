defmodule HelpfulOptions.SwitchErrors do
  @moduledoc """
  Error struct for switch validation failures.

  Covers missing, invalid, incorrect, and unknown switches.
  Implements `String.Chars` to produce human-readable error messages.
  """

  alias HelpfulOptions.Switches

  @type t :: %__MODULE__{
          invalid: invalid,
          missing: missing,
          incorrect: incorrect,
          unknown: [String.t()]
        }
  @type invalid :: Keyword.t()
  @type missing :: [atom]
  @type incorrect :: [%{type: Switches.switch_type(), values: [String.t()]}]

  defstruct ~w(missing incorrect invalid unknown)a

  defimpl String.Chars do
    alias HelpfulOptions.SwitchErrors

    @spec to_string(SwitchErrors.t()) :: String.t()
    def to_string(%SwitchErrors{invalid: invalid}) when not is_nil(invalid) do
      invalid
      |> Enum.map(&invalid_to_string/1)
      |> Enum.join("\n")
    end

    def to_string(%SwitchErrors{missing: missing}) when is_list(missing) do
      switches =
        missing
        |> Enum.map(&"--#{&1}")
        |> Enum.join(", ")

      "Please supply the following parameters: #{switches}"
    end

    def to_string(%SwitchErrors{incorrect: incorrect}) when is_list(incorrect) do
      incorrect
      |> Enum.map(&incorrect_to_string/1)
      |> Enum.join(", ")
    end

    def to_string(%SwitchErrors{unknown: unknown}) when is_list(unknown) do
      unknown
      |> Enum.map(& "#{&1} - unknown switch")
      |> Enum.join(", ")
    end

    defp invalid_to_string({name, {:invalid_type, type}}) do
      "--#{name} - type '#{type}' is unknown"
    end

    defp invalid_to_string({name, :required_and_default}) do
      "--#{name} - only specify one of `:required` and `:default`"
    end

    defp incorrect_to_string({name, %{type: type, values: values}}) do
      "--#{name} - incorrect values #{inspect(values)} supplied for #{type}"
    end
  end
end
