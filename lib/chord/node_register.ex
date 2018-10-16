defmodule Chord.NodeRegister do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, name: Chord.NodeRegister)
  end

  def insert_node(register, pid, id) do
    GenServer.cast(register, {:insert, pid, id})
  end

  def get_node(register, from_id) do
    GenServer.call(register, {:get, from_id})
  end

  def init(_opts) do
    register = MapSet.new()
    {:ok, register}
  end

  def handle_cast({:insert, pid, id}, register) do
    register = MapSet.put(register, {pid, id})
    {:noreply, register}
  end

  def handle_call({:get, from_id}, {from_pid, _from_ref}, register) do
    {entry_pid, _entry_id} = Enum.random(register)
    register = MapSet.put(register, {from_pid, from_id})
    {:reply, entry_pid, register}
  end
end
