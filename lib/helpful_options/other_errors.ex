defmodule HelpfulOptions.OtherErrors do
  @moduledoc """
  Error struct for "other" parameter validation failures.

  Implements `String.Chars` to produce human-readable error messages.
  """

  @type t :: %__MODULE__{
          actual: non_neg_integer,
          min: non_neg_integer,
          max: non_neg_integer,
          required: non_neg_integer,
          unexpected: [String.t()]
        }
  defstruct ~w(actual min max required unexpected)a

  defimpl String.Chars do
    alias HelpfulOptions.OtherErrors

    @spec to_string(OtherErrors.t()) :: String.t()
    def to_string(%OtherErrors{actual: actual, required: required}) when not is_nil(required) do
      "Expected #{required} other parameters, but got #{actual}"
    end

    def to_string(%OtherErrors{unexpected: unexpected}) when not is_nil(unexpected) do
      "No other parameters were expected, but got '#{Enum.join(unexpected, ", ")}'"
    end

    def to_string(%OtherErrors{actual: actual, min: min, max: nil, required: nil}) do
      "Expected at least #{min} other parameters, but got #{actual}"
    end

    def to_string(%OtherErrors{actual: actual, min: nil, max: max, required: nil}) do
      "Expected at most #{max} other parameters, but got #{actual}"
    end

    def to_string(%OtherErrors{actual: actual, max: max, min: min, required: nil}) do
      "Expected between #{min} and #{max} other parameters, but got #{actual}"
    end
  end
end
