defmodule Chord.IntervalChecker do
  require Logger

  def check_open_interval(n, lower_limit, upper_limit) do
    cond do
      lower_limit < upper_limit ->
        n > lower_limit && n < upper_limit

      lower_limit > upper_limit ->
        n > lower_limit || n < upper_limit

      lower_limit == upper_limit ->
        true

      true ->
        false
    end
  end

  def check_half_open_interval(n, lower_limit, upper_limit) do
    cond do
      lower_limit < upper_limit ->
        n > lower_limit && n <= upper_limit

      lower_limit > upper_limit ->
        n > lower_limit || n <= upper_limit

      lower_limit == upper_limit ->
        true

      true ->
        false
    end
  end
end
