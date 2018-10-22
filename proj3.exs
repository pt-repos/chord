defmodule Proj3 do
	def run(num_nodes, num_requests) do
		
		{:ok, pid} = Chord.Monitor.start_link([num_nodes: num_nodes, num_requests: num_requests])
		Chord.Monitor.start_simulation(pid)
		loop()
	end

	def loop() do
		receive do
			{:avg_hops, avg_hops} ->
				IO.puts("Average numbe of hops = #{avg_hops}")
		end
	end
end

usage_string = "Invalid arguments to the command\nUsage: mix run proj3.exs <numNodes:int> <numRequests:int>"
if length(System.argv) != 2 do
  raise(ArgumentError, usage_string)
end

[num_nodes, num_requests] = System.argv
num_nodes = String.to_integer(num_nodes)
num_requests = String.to_integer(num_requests)

Proj3.run(num_nodes, num_requests)

# {:ok, supervisor} = Chord.Supervisor.start_link([])
# {:ok, register} = Chord.NodeRegister.start_link([])
# {:ok, node_pids} = Chord.Supervisor.start_nodes(supervisor, 250, register)

# {:ok, repo} = Chord.Repository.start_link([node_register: register])
# Chord.Repository.insert(repo, data)

# Enum.each(node_pids, fn node_pid-> 
# 	IO.inspect :sys.get_state(node_pid)
# end)