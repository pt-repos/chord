defmodule Chord.Node do
  use GenServer

  @moduledoc """
  Node
  """

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

    identifier = :crypto.hash(:sha, ip_addr) |> binary_part(0, 1) |> Base.encode16()

    node_register = Keyword.get(opts, :node_register)

    m = Keyword.get(opts, :num_fingers)

    finger_fixer = spawn(Chord.FingerFixer, :run, [identifier, self(), Map.new(), -1, m, nil])

    {:ok,
     [
       ip_addr: ip_addr,
       identifier: identifier,
       successor: nil,
       predecessor: nil,
       node_register: node_register,
       m: m,
       finger_table: Map.new(),
       finger_fixer: finger_fixer
     ]}
  end

  def handle_cast({:create}, state) do
    Chord.NodeRegister.insert_node(state[:node_register], self(), state[:identifier])
    state = Keyword.put(state, :successor, state[:identifier])
    send(state[:finger_fixer], {:start})

    {:noreply, state}
  end

  def handle_cast({:join}, state) do
    network_node = Chord.NodeRegister.get_node(state[:node_register], state[:identifier])
    successor = Chord.Node.find_successor(network_node, state[:identifier])
    state = Keyword.put(state, :successor, successor)
    send(state[:finger_fixer], {:start})

    {:noreply, state}
  end

  # TODO: handle mod
  def handle_call({:find_successor, id}, _from, state) do
    successor =
      if id > state[:identifier] && id <= state[:successor] do
        state[:successor]
      else
        next_node =
          closest_preceding_node(id, state[:m], state[:finger_table], state[:identifier])

        IO.inspect(state[:finger_table])
        IO.puts("next_node")
        IO.inspect(next_node)

        if next_node != self() do
          Chord.Node.find_successor(next_node, id)
        else
          state[:successor]
        end
      end

    {:reply, successor, state}
  end

  defp closest_preceding_node(id, m, finger_table, node_identifier) do
    if Enum.empty?(finger_table) do
      self()
    else
      key = m - 1
      entry = Map.get(finger_table, key)
      # entry = Enum.at(finger_table, key)

      # CONDITION: if (entry_identifier E (node_identifier, id) )

      # Can do with only the second condition? as entries are +2^m successors of node in the ring.
      if entry[:identifier] > node_identifier && entry[:identifier] < id do
        # if entry[:identifier] < id do
        entry[:pid]
      else
        closest_preceding_node(id, m, finger_table, node_identifier, key - 1)
      end
    end
  end

  defp closest_preceding_node(id, m, finger_table, node_identifier, key) do
    if key >= 0 do
      entry = Map.get(finger_table, key)
      # entry = Enum.at(finger_table, key)

      # Can do with only the second condition? as entries are +2^m successors of node in the ring.
      if entry[:identifier] > node_identifier && entry[:identifier] < id do
        # if entry[:identifier] < id do
        entry[:pid]
      else
        closest_preceding_node(id, m, finger_table, node_identifier, key - 1)
      end
    else
      IO.puts("self()")
      self()
    end
  end
end
