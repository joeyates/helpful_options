defmodule HelpfulOptions.Errors do
  @moduledoc """
  Represents an error that occurred while parsing options.
  """
  alias HelpfulOptions.Errors.{Subcommands, Switches, Other}

  @type t :: %__MODULE__{
          subcommands: Subcommands.t(),
          switches: Switches.t(),
          other: Other.t()
        }
  defstruct ~w(subcommands switches other)a
end
