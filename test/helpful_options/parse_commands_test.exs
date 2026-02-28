defmodule HelpfulOptions.ParseCommandsTest do
  use ExUnit.Case, async: true

  describe "parse_commands/2" do
    test "most specific (longest) command match wins" do
      definitions = [
        %{commands: ["remote"], switches: nil, other: nil},
        %{commands: ["remote", "add"], switches: [name: %{type: :string}], other: nil}
      ]

      assert {:ok, ["remote", "add"], %{name: "origin"}, []} =
               HelpfulOptions.parse_commands(["remote", "add", "--name", "origin"], definitions)
    end

    test "matches root command with empty commands list" do
      definitions = [
        %{commands: ["sub"], switches: nil, other: nil},
        %{commands: [], switches: [verbose: %{type: :boolean}], other: :any}
      ]

      assert {:ok, [], %{verbose: true}, ["file"]} =
               HelpfulOptions.parse_commands(["--verbose", "file"], definitions)
    end

    test "returns unknown_command when no definition matches" do
      definitions = [
        %{commands: ["remote"], switches: nil, other: nil}
      ]

      assert {:error, {:unknown_command, ["branch"]}} =
               HelpfulOptions.parse_commands(["branch", "--verbose"], definitions)
    end

    test "returns unknown_command with empty subcommands when no root definition exists" do
      definitions = [
        %{commands: ["remote"], switches: nil, other: nil}
      ]

      assert {:error, {:unknown_command, []}} =
               HelpfulOptions.parse_commands(["--verbose"], definitions)
    end

    test "returns duplicate_commands error when definitions share the same commands" do
      definitions = [
        %{commands: ["remote"], switches: nil, other: nil},
        %{commands: ["remote"], switches: [verbose: %{type: :boolean}], other: nil}
      ]

      assert {:error, {:duplicate_commands, ["remote"]}} =
               HelpfulOptions.parse_commands(["remote"], definitions)
    end

    test "propagates parse errors from parse/2" do
      definitions = [
        %{commands: ["run"], switches: [count: %{type: :integer}], other: nil}
      ]

      assert {:error, %HelpfulOptions.Errors{switches: %HelpfulOptions.SwitchErrors{incorrect: [{"--count", "abc"}]}}} =
               HelpfulOptions.parse_commands(["run", "--count", "abc"], definitions)
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
  end

  describe "parse_commands!/2" do
    test "returns tuple on success" do
      definitions = [
        %{commands: ["run"], switches: [verbose: %{type: :boolean}], other: nil}
      ]

      assert {["run"], %{verbose: true}, []} =
               HelpfulOptions.parse_commands!(["run", "--verbose"], definitions)
    end

    test "raises ArgumentError on unknown command" do
      definitions = [
        %{commands: ["run"], switches: nil, other: nil}
      ]

      assert_raise ArgumentError, "unknown command: deploy", fn ->
        HelpfulOptions.parse_commands!(["deploy"], definitions)
      end
    end

    test "raises ArgumentError on duplicate commands" do
      definitions = [
        %{commands: ["run"], switches: nil, other: nil},
        %{commands: ["run"], switches: nil, other: nil}
      ]

      assert_raise ArgumentError, "duplicate commands: run", fn ->
        HelpfulOptions.parse_commands!(["run"], definitions)
      end
    end

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
