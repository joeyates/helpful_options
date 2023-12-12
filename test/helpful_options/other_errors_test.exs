defmodule HelpfulOptions.OtherErrorsTest do
  use ExUnit.Case, async: true

  test "min and max" do
    result =
      %HelpfulOptions.OtherErrors{max: 3, min: 2, actual: 1}
      |> to_string()

    assert result == "Expected between 2 and 3 other parameters, but got 1"
  end

  test "min" do
    result =
      %HelpfulOptions.OtherErrors{min: 2, actual: 1}
      |> to_string()

    assert result == "Expected at least 2 other parameters, but got 1"
  end

  test "max" do
    result =
      %HelpfulOptions.OtherErrors{max: 3, actual: 5}
      |> to_string()

    assert result == "Expected at most 3 other parameters, but got 5"
  end

  test "required" do
    result =
      %HelpfulOptions.OtherErrors{required: 2, actual: 1}
      |> to_string()

    assert result == "Expected 2 other parameters, but got 1"
  end

  test "unexpected" do
    result =
      %HelpfulOptions.OtherErrors{unexpected: ["ciao"]}
      |> to_string()

    assert result == "No other parameters were expected, but got 'ciao'"
  end
end
