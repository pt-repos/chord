defmodule Proj3 do
	def run(num_nodes, num_requests) do
		
		{:ok, pid} = Chord.Monitor.start_link([num_nodes: num_nodes, num_requests: num_requests])
		Chord.Monitor.start_simulation(pid)
		loop()
	end

	def loop() do
		receive do
			{:avg_hops, avg_hops} ->
				IO.puts("Average number of hops = #{avg_hops}")
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

{time, :ok} = :timer.tc(Proj3, :run, [num_nodes, num_requests])

IO.puts("\nexecution time: #{inspect(time/1000/1000)} sec")
