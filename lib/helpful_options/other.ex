defmodule HelpfulOptions.Other do
  @moduledoc """
  Validates the count of non-switch, non-subcommand arguments ("other" parameters).

  Supports exact counts, min/max ranges, and `:any` to accept any number.
  """

  alias HelpfulOptions.OtherErrors

  @type t :: other_options | :any | nil
  @type other_options ::
          %{min: non_neg_integer, max: non_neg_integer}
          | %{min: non_neg_integer}
          | %{max: non_neg_integer}
          | non_neg_integer()

  @spec check([String.t()], t()) :: {:ok} | {:error, HelpfulOptions.Errors.t()}
  @doc ~S"""
  You can specify how many other parameters are required:

      iex> HelpfulOptions.Other.check(["first", "second"], 2)
      {:ok}

  You can indicate limits with `:min` and/or `:max`:

      iex> HelpfulOptions.Other.check(["first", "second"], %{min: 2, max: 3})
      {:ok}

  Alternatively, you can accept any number of other parameters with `:any`:

      iex> HelpfulOptions.Other.check(["first", "second"], :any)
      {:ok}

  It's an error if you specify a count and the wrong number of other parameters is supplied:

      iex> HelpfulOptions.Other.check(["first"], 2)
      {:error, %HelpfulOptions.OtherErrors{required: 2, actual: 1}}

  It's also an error if other parameters are supplied when none were specified:

      iex> HelpfulOptions.Other.check(["pizza"], nil)
      {:error, %HelpfulOptions.OtherErrors{unexpected: ["pizza"]}}

  Or, if they are outside the indicated range:

      iex> HelpfulOptions.Other.check(["first"], %{min: 2, max: 3})
      {:error, %HelpfulOptions.OtherErrors{max: 3, min: 2, actual: 1}}
  """
  def check(other, required)

  def check(_other, :any), do: {:ok}

  def check(other, %{min: min, max: max}) do
    length = length(other)

    if length >= min && length <= max do
      {:ok}
    else
      {:error, %OtherErrors{min: min, max: max, actual: length}}
    end
  end

  def check(other, %{min: min}) do
    if length(other) >= min do
      {:ok}
    else
      {:error, %OtherErrors{min: min, actual: length(other)}}
    end
  end

  def check(other, %{max: max}) do
    if length(other) <= max do
      {:ok}
    else
      {:error, %OtherErrors{max: max, actual: length(other)}}
    end
  end

  def check(other, required) when is_integer(required) do
    if length(other) == required do
      {:ok}
    else
      {:error, %OtherErrors{required: required, actual: length(other)}}
    end
  end

  def check([], nil) do
    {:ok}
  end

  def check(other, nil) do
    {:error, %OtherErrors{unexpected: other}}
  end
end
