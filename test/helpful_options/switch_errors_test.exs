defmodule HelpfulOptions.SwitchErrorsTest do
  use ExUnit.Case, async: true

  alias HelpfulOptions.SwitchErrors

  test "invalid - type" do
    result =
      %SwitchErrors{invalid: [{:foo, {:invalid_type, :ciao}}]}
      |> to_string()

    assert result == "--foo - type 'ciao' is unknown"
  end

  test "invalid - required and default" do
    result =
      %SwitchErrors{invalid: [{:foo, :required_and_default}]}
      |> to_string()

    assert result == "--foo - only specify one of `:required` and `:default`"
  end

  test "incorrect supplied value" do
    result =
      %SwitchErrors{incorrect: [{:foo, %{type: :integer, values: ["ciao"]}}]}
      |> to_string()

    assert result == "--foo - incorrect values [\"ciao\"] supplied for integer"
  end

  test "unknown switch" do
    result =
      %SwitchErrors{unknown: ["--foo"]}
      |> to_string()

    assert result == "--foo - unknown switch"
  end
end
