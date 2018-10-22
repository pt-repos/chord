defmodule Chord.Supervisor do
  use DynamicSupervisor

  def start_link(_opts) do
    # IO.puts("starting supervisor")
    DynamicSupervisor.start_link(__MODULE__, name: Chord.Supervisor)
  end

  def start_nodes(supervisor, num_nodes, num_requests, monitor, node_register) do
    # num_fingers = round(:math.log2(num_nodes))
    num_fingers = :math.log2(num_nodes)

    node_pids =
      for n <- 1..num_nodes do
        {:ok, node_pid} =
          DynamicSupervisor.start_child(
            supervisor,
            {Chord.Node,
             [
               node_register: node_register,
               monitor: monitor,
               num_fingers: num_fingers,
               num_requests: num_requests
             ]}
          )

        if n != 1 do
          # Process.sleep(100)
          Chord.Node.join(node_pid)
        else
          Chord.Node.create(node_pid)
        end

        node_pid
      end

    {:ok, node_pids}
  end

  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_node_register(supervisor) do
    DynamicSupervisor.start_child(supervisor, {Chord.NodeRegister, []})
  end
end
