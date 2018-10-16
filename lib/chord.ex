defmodule Chord do
  use Application

  @moduledoc """
  Documentation for Chord.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Chord.hello()
      :world

  """
  def hello do
    :world
  end

  def start(_type, _args) do
    Chord.Supervisor.start_link([])
  end
end
