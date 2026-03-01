defmodule HelpfulOptions.ParseCommandsTest do
  use ExUnit.Case, async: true

  describe "parse_commands/2" do
    test "with no subcommands and no arguments" do
      definitions = [
        %{commands: [], switches: nil}
      ]

      assert {:ok, %HelpfulOptions.ParsedCommand{commands: [], switches: %{}, other: []}} =
               HelpfulOptions.parse_commands([], definitions)
    end

    test "duplicate :any definitions are detected" do
      definitions = [
        %{commands: [:any], switches: nil},
        %{commands: [:any], switches: [verbose: %{type: :boolean}]}
      ]

      assert {:error, {:duplicate_commands, [:any]}} =
               HelpfulOptions.parse_commands(["something"], definitions)
    end
  end

  describe "parse_commands!/2" do
    test "raises on parse error" do
      definitions = [
        %{commands: ["run"], switches: [count: %{type: :integer}]}
      ]

      assert_raise FunctionClauseError, fn ->
        HelpfulOptions.parse_commands!(["run", "--count", "abc"], definitions)
      end
    end
  end
end
