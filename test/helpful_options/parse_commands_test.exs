defmodule HelpfulOptions.ParseCommandsTest do
  use ExUnit.Case, async: true

  describe "parse_commands/2" do
    test "returns unknown_command with empty subcommands when no root definition exists" do
      definitions = [
        %{commands: ["remote"], switches: nil, other: nil}
      ]

      assert {:error, {:unknown_command, []}} =
               HelpfulOptions.parse_commands(["--verbose"], definitions)
    end

    test "handles other arguments correctly" do
      definitions = [
        %{commands: ["deploy"], switches: [env: %{type: :string}], other: 1}
      ]

      assert {:ok, ["deploy"], %{env: "prod"}, ["myapp"]} =
               HelpfulOptions.parse_commands(["deploy", "--env", "prod", "myapp"], definitions)
    end

    test "returns other error when wrong number of other args" do
      definitions = [
        %{commands: ["deploy"], switches: nil, other: 2}
      ]

      assert {:error, %HelpfulOptions.Errors{other: %HelpfulOptions.OtherErrors{required: 2, actual: 1}}} =
               HelpfulOptions.parse_commands(["deploy", "--", "one"], definitions)
    end

    test "with no subcommands and no arguments" do
      definitions = [
        %{commands: [], switches: nil, other: nil}
      ]

      assert {:ok, [], %{}, []} =
               HelpfulOptions.parse_commands([], definitions)
    end

    test ":any matches a single arbitrary subcommand" do
      definitions = [
        %{commands: [:any], switches: [verbose: %{type: :boolean}], other: nil}
      ]

      assert {:ok, [:any], %{verbose: true}, []} =
               HelpfulOptions.parse_commands(["something", "--verbose"], definitions)
    end

    test "[:any, \"add\"] matches [\"remote\", \"add\"]" do
      definitions = [
        %{commands: [:any, "add"], switches: [name: %{type: :string}], other: nil}
      ]

      assert {:ok, [:any, "add"], %{name: "origin"}, []} =
               HelpfulOptions.parse_commands(["remote", "add", "--name", "origin"], definitions)
    end

    test "[:any, \"add\"] does not match [\"remote\", \"remove\"]" do
      definitions = [
        %{commands: [:any, "add"], switches: [name: %{type: :string}], other: nil}
      ]

      assert {:error, {:unknown_command, ["remote", "remove"]}} =
               HelpfulOptions.parse_commands(["remote", "remove", "--name", "origin"], definitions)
    end

    test "exact definition is preferred over :any definition of equal length" do
      definitions = [
        %{commands: ["remote", "add"], switches: [name: %{type: :string}], other: nil},
        %{commands: [:any, "add"], switches: [label: %{type: :string}], other: nil}
      ]

      assert {:ok, ["remote", "add"], %{name: "origin"}, []} =
               HelpfulOptions.parse_commands(["remote", "add", "--name", "origin"], definitions)
    end

    test "duplicate :any definitions are detected" do
      definitions = [
        %{commands: [:any], switches: nil, other: nil},
        %{commands: [:any], switches: [verbose: %{type: :boolean}], other: nil}
      ]

      assert {:error, {:duplicate_commands, [:any]}} =
               HelpfulOptions.parse_commands(["something"], definitions)
    end
  end

  describe "parse_commands!/2" do
    test "raises on parse error" do
      definitions = [
        %{commands: ["run"], switches: [count: %{type: :integer}], other: nil}
      ]

      assert_raise FunctionClauseError, fn ->
        HelpfulOptions.parse_commands!(["run", "--count", "abc"], definitions)
      end
    end
  end
end
