defmodule Chord.Repository do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Chord.Repository)
  end

  def insert(pid, data) do
    GenServer.cast(pid, {:insert, pid, data})
  end

  def lookup(pid, data) do
    GenServer.call(pid, {:lookup, data})
  end

  def init(_opts) do
    {:ok}
  end

  def handle_cast({:insert, pid, data}, :ok) do
    key = :crypto.hash(:sha, data)
    Chord.Node.find_successor(pid, key)

    successor =
      receive do
        {:successor, successor, _hop_count} ->
          successor
      end

    Chord.Node.insert_data(successor[:pid], key, data)

    {:noreply, :ok, :ok}
  end

  def handle_call({:lookup, pid, data}, _from, :ok) do
    key = :crypto.hash(:sha, data)
    Chord.Node.find_successor(pid, key)

    {successor, hop_count} =
      receive do
        {:successor, successor, hop_count} ->
          {successor, hop_count}
      end

    data = Chord.Node.get_data(successor[:pid], key)

    {:reply, {data, successor, hop_count}, :ok}
  end
end
