defmodule HelpfulOptions.ErrorsTest do
  use ExUnit.Case, async: true

  test "switches to_string" do
    result =
      to_string(%HelpfulOptions.Errors{other: %HelpfulOptions.SwitchErrors{missing: [:foo]}})

    assert result == "Please supply the following parameters: --foo"
  end

  test "others to_string" do
    result =
      to_string(%HelpfulOptions.Errors{
        other: %HelpfulOptions.OtherErrors{max: 3, min: 2, actual: 1}
      })

    assert result == "Expected between 2 and 3 other parameters, but got 1"
  end
end
