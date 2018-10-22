defmodule Chord.Repository do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Chord.Repository)
  end

  def insert(pid, data) do
    GenServer.cast(pid, {:insert, data})
  end

  def lookup(pid, data) do
    GenServer.call(pid, {:lookup, data})
  end

  def init(opts) do
    register = opts[:node_register]

    {:ok, register}
    # {:ok,
    #  [
    #    node_register: register
    #  ]}
  end

  def handle_cast({:insert, data}, register) do
    network_node = Chord.NodeRegister.get_node(register, nil)
    key = :crypto.hash(:sha, data[:key])
    successor = Chord.Node.find_successor(network_node, key)
    Chord.Node.insert_data(successor[:pid], key, data[:value])
  end

  # def handle_call({:lookup, data}, register) do
  #   network_node
  # end
end
