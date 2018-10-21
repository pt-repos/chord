defmodule Chord.Node do
  use GenServer
  require Logger

  @moduledoc """
  Node
  """

  # Client
  def start_link(opts) do
    # Logger.info("test #{inspect(opts)} \n test2")
    GenServer.start_link(__MODULE__, opts)
  end

  def create(pid) do
    GenServer.cast(pid, {:create})
  end

  def join(pid) do
    GenServer.cast(pid, {:join})
  end

  def update_finger_table(pid, finger_table) do
    GenServer.cast(pid, {:update_finger_table, finger_table})
  end

  def notify(pid, new_predecessor) do
    GenServer.cast(pid, {:notify, new_predecessor})
  end

  def update_successor(node_pid, new_successor) do
    GenServer.cast(node_pid, {:update_successor, new_successor})
  end

  def find_successor(pid, id) do
    GenServer.call(pid, {:find_successor, id})
  end

  def get_predecessor(pid) do
    GenServer.call(pid, {:get_predecessor})
  end

  # Server
  def init(opts) do
    node_register = Keyword.get(opts, :node_register)

    m = Keyword.get(opts, :num_fingers)
    # m = 160

    ip_addr =
      Integer.to_string(:rand.uniform(255)) <> "." <> Integer.to_string(:rand.uniform(255))

    n = Keyword.get(opts, :n)

    # identifier = :crypto.hash(:sha, ip_addr) |> binary_part(0, 1)
    identifier = :crypto.hash(:sha, Integer.to_string(n)) |> binary_part(0, 1)

    finger_fixer = spawn(Chord.FingerFixer, :run, [identifier, self(), Map.new(), -1, m, nil])

    stabilizer = spawn(Chord.Stabilizer, :run, [identifier, self(), nil, nil])

    {:ok,
     [
       pid: self(),
       joining_node: nil,
       n: n,
       ip_addr: ip_addr,
       identifier: identifier,
       successor: nil,
       predecessor: nil,
       node_register: node_register,
       m: m,
       finger_table: Map.new(),
       finger_fixer: finger_fixer,
       stabilizer: stabilizer
     ]}
  end

  def handle_cast({:create}, state) do
    Chord.NodeRegister.insert_node(state[:node_register], self(), state[:identifier])
    state = Keyword.put(state, :successor, identifier: state[:identifier], pid: self())
    send(state[:finger_fixer], {:start})
    send(state[:stabilizer], {:start, state[:successor]})

    {:noreply, state}
  end

  def handle_cast({:join}, state) do
    network_node = Chord.NodeRegister.get_node(state[:node_register], state[:identifier])
    state = Keyword.put(state, :joining_node, network_node)
    successor = Chord.Node.find_successor(network_node, state[:identifier])
    state = Keyword.put(state, :successor, successor)
    send(state[:finger_fixer], {:start})
    send(state[:stabilizer], {:start, state[:successor]})
    # IO.inspect(state)

    {:noreply, state}
  end

  def handle_cast({:update_finger_table, finger_table}, state) do
    state = Keyword.put(state, :finger_table, finger_table)
    # IO.inspect(state)

    {:noreply, state}
  end

  def handle_cast({:update_successor, new_successor}, state) do
    state = Keyword.put(state, :successor, new_successor)

    {:noreply, state}
  end

  def handle_cast({:notify, new_predecessor}, state) do
    state =
      if is_nil(state[:predecessor]) ||
           Chord.IntervalChecker.check_open_interval(
             new_predecessor[:identifier],
             state[:predecessor][:identifier],
             state[:identifier]
           ) do
        Keyword.put(state, :predecessor, new_predecessor)
      else
        state
      end

    {:noreply, state}
  end

  def handle_call({:get_predecessor}, _from, state) do
    {:reply, state[:predecessor], state}
  end

  # TODO: handle mod
  def handle_call({:find_successor, id}, _from, state) do
    # IO.puts("inside find_successor")
    # IO.inspect(state)
    # Logger.info("inside find successor
    #   \nid:\t#{inspect(id)}
    #   \nstate_id:\t#{inspect(state[:identifier])}
    #   \nstate_succ_id:\t#{inspect(state[:successor][:identifier])}")

    successor =
      if(
        Chord.IntervalChecker.check_half_open_interval(
          id,
          state[:identifier],
          state[:successor][:identifier]
        )
      ) do
        state[:successor]
      else
        # IO.puts("333333\nidentifier #{state[:identifier]}")
        next_node =
          closest_preceding_node(id, state[:m], state[:finger_table], state[:identifier])

        # IO.puts("next_node")
        # Logger.info("next_node:\t#{inspect(next_node)}")
        # IO.inspect(state)
        # IO.inspect(state[:finger_table])
        # IO.puts("next_node")
        # IO.inspect(next_node)

        if next_node != self() do
          Chord.Node.find_successor(next_node, id)
        else
          state[:successor]
        end
      end

    # if id > state[:identifier] && id <= state[:successor][:identifier] do
    #   state[:successor]
    # else
    #   # IO.puts("333333\nidentifier #{state[:identifier]}")

    #   next_node = closest_preceding_node(id, state[:m], state[:finger_table], state[:identifier])

    #   # IO.puts("next_node")
    #   # Logger.info("next_node:\t#{inspect(next_node)}")
    #   # IO.inspect(state)
    #   # IO.inspect(state[:finger_table])
    #   # IO.puts("next_node")
    #   # IO.inspect(next_node)

    #   if next_node != self() do
    #     Chord.Node.find_successor(next_node, id)
    #   else
    #     state[:successor]
    #   end
    # end

    # Logger.info("successor: #{inspect(successor)}")

    {:reply, successor, state}
  end

  defp closest_preceding_node(id, m, finger_table, node_identifier) do
    Logger.info("inside cpn")

    if Enum.empty?(finger_table) do
      # IO.puts("#### finger_table empty")
      self()
    else
      # IO.puts("#### finger_table NOT empty #{node_identifier}")
      key = map_size(finger_table) - 1
      entry = Map.get(finger_table, key)
      Logger.info("finger_table #{inspect(finger_table)}")
      Logger.info("entry: #{inspect(entry)}")
      # entry = Enum.at(finger_table, key)

      # CONDITION: if (entry_identifier E (node_identifier, id) )

      # Can do with only the second condition? as entries are +2^m successors of node in the ring.
      # if entry[:identifier] > node_identifier && entry[:identifier] < id do
      if !is_nil(entry) &&
           Chord.IntervalChecker.check_open_interval(entry[:identifier], node_identifier, id) do
        entry[:pid]
      else
        closest_preceding_node(id, m, finger_table, node_identifier, key - 1)
      end
    end
  end

  defp closest_preceding_node(id, m, finger_table, node_identifier, key) do
    # Logger.info("inside cpn")

    if key >= 0 do
      # IO.puts("#### key >= 0; #{key}")
      entry = Map.get(finger_table, key)

      # entry = Enum.at(finger_table, key)

      # Can do with only the second condition? as entries are +2^m successors of node in the ring.
      # if entry[:identifier] > node_identifier && entry[:identifier] < id do
      if !is_nil(entry) &&
           Chord.IntervalChecker.check_open_interval(entry[:identifier], node_identifier, id) do
        entry[:pid]
      else
        closest_preceding_node(id, m, finger_table, node_identifier, key - 1)
      end
    else
      # IO.puts("self()")
      # IO.inspect(self())
      self()
    end
  end
end
