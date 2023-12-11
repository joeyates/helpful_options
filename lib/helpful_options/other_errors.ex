defmodule HelpfulOptions.OtherErrors do
  @type t :: %__MODULE__{
          actual: non_neg_integer,
          count: non_neg_integer,
          min: non_neg_integer,
          max: non_neg_integer,
          incorrect: String.t(),
          required: non_neg_integer,
          unexpected: [String.t()]
        }
  defstruct ~w(actual count min max incorrect required unexpected)a
end
