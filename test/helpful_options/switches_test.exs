defmodule HelpfulOptions.SwitchesTest do
  use ExUnit.Case, async: true
  doctest HelpfulOptions.Switches

  def test "optional parameters" do
    {:ok, help} = HelpfulOptions.Switches.help(foo: %{type: :string})
    assert String.contains?(help, "Optional parameter")
  end

  _a = """
      iex> HelpfulOptions.Switches.help(foo: %{type: :string, required: true})
      {:ok, "  --foo=FOO                    Required"}

      iex> HelpfulOptions.Switches.help(foo: %{type: :string, default: "bar"})
      {:ok, "  --foo=FOO                    Optional parameter. Default: bar"}

      iex> HelpfulOptions.Switches.help(foo: %{type: :string, description: "A description"})
      {:ok, "  --foo=FOO                    A description"}

      iex> HelpfulOptions.Switches.help(foo: %{type: :string, short: :f})
      {:ok, "-f FOO, --foo=FOO              Optional parameter"}
  """
end
