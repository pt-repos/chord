defmodule Chord.Node do
  use GenServer

  @moduledoc """
  Node
  """

  @m 5

  # Client
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def create(pid) do
    GenServer.cast(pid, {:create})
  end

  def join(pid) do
    GenServer.cast(pid, {:join})
  end

  def find_successor(pid, id) do
    GenServer.call(pid, {:find_successor, id})
  end

  # Server
  def init(opts) do
    ip_addr =
      Integer.to_string(:rand.uniform(255)) <> "." <> Integer.to_string(:rand.uniform(255))

    identifier = :crypto.hash(:sha, ip_addr) |> binary_part(0, 2) |> Base.encode16()

    node_register = Keyword.get(opts, :node_register)

    finger_fixer = spawn(Chord.FingerFixer, :run, [identifier, self(), [], -1, @m, nil])

    {:ok,
     [
       ip_addr: ip_addr,
       identifier: identifier,
       successor: nil,
       predecessor: nil,
       node_register: node_register,
       finger_table: [],
       finger_fixer: finger_fixer
     ]}
  end

  def handle_cast({:create}, state) do
    Chord.NodeRegister.insert_node(state[:node_register], self(), state[:identifier])
    state = Keyword.put(state, :successor, state[:identifier])
    {:noreply, state}
  end

  def handle_cast({:join}, state) do
    network_node = Chord.NodeRegister.get_node(state[:node_register], state[:identifier])
    successor = Chord.Node.find_successor(network_node, state[:identifier])
    state = Keyword.put(state, :successor, successor)

    {:noreply, state}
  end

  def handle_call({:find_successor, id}, _from, state) do
    successor =
      if id > state[:identifier] && id <= state[:successor] do
        state[:successor]
      else
        next_node = closest_preceding_node(id, state[:finger_table], state[:identifier])

        if next_node != self() do
          Chord.Node.find_successor(next_node, id)
        else
          state[:successor]
        end
      end

    {:reply, successor, state}
  end

  def closest_preceding_node(id, finger_table, node_identifier) do
    index = @m - 1
    entry = Enum.at(finger_table, index)

    if entry[:identifier] > node_identifier && entry[:identifier] < id do
      entry[:pid]
    else
      closest_preceding_node(id, finger_table, node_identifier, index - 1)
    end
  end

  defp closest_preceding_node(id, finger_table, node_identifier, index) do
    if index >= 0 do
      entry = Enum.at(finger_table, index)

      if entry[:identifier] > node_identifier && entry[:identifier] < id do
        entry[:pid]
      else
        closest_preceding_node(id, finger_table, node_identifier, index - 1)
      end
    else
      self()
    end
  end
end
