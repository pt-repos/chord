defmodule Chord.Monitor do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def start_simulation(pid) do
    GenServer.call(pid, {:start}, :infinity)
  end

  def init(opts) do
    num_nodes = opts[:num_nodes]
    num_requests = opts[:num_requests]
    total_hops = 0
    counter = 0
    report_pid = nil

    {:ok, {num_nodes, num_requests, total_hops, counter, report_pid}}
  end

  def handle_call(
        {:start},
        {from_pid, _ref},
        {num_nodes, num_requests, total_hops, counter, _report_pid}
      ) do
    {:ok, supervisor} = Chord.Supervisor.start_link([])
    {:ok, register} = Chord.NodeRegister.start_link([])
    {:ok, _repo} = Chord.Repository.start_link(node_register: register)

    IO.puts("Creating node and forming network")

    {:ok, _node_pids} =
      Chord.Supervisor.start_nodes(supervisor, num_nodes, num_requests, self(), register)

    # IO.puts("#{inspect(node_pids)}")

    {:reply, :ok, {num_nodes, num_requests, total_hops, counter, from_pid}}
  end

  def handle_info({:avg_hops, hops}, {num_nodes, num_requests, total_hops, counter, report_pid}) do
    total_hops = total_hops + hops
    counter = counter + 1

    if Enum.random(1..1000) < 5 do
      IO.puts("counter: #{counter}")
    end

    # IO.puts("counter: #{counter},\thops: #{hops}")

    if counter == num_nodes do
      avg_hops = total_hops / num_nodes
      send(report_pid, {:avg_hops, avg_hops})
    end

    ProgressBar.render(counter, num_nodes)

    # if counter == 5 do
    #   avg_hops = total_hops / 5
    #   send(report_pid, {:avg_hops, avg_hops})
    # end

    {:noreply, {num_nodes, num_requests, total_hops, counter, report_pid}}
  end
end
