defmodule Chord.RequestMaker do
  @request_interval 1000

  def start(pid) do
    # IO.puts("starting ticker")
    Chord.Ticker.start(pid, @request_interval)
  end

  def stop(pid) do
    Chord.Ticker.stop(pid)
  end

  def run(node_pid, node_register, total_requests, num_requests, total_hops, monitor, ticker_pid) do
    receive do
      {:tick, _index} ->
        # IO.puts("#{inspect(node_pid)} sending lookup request")
        # num_requests = num_requests - 1

        # string = Randomizer.randomizer(6)
        # key = :crypto.hash(:sha, string)
        # {_successor, hops} = Chord.Node.lookup(node_pid, key)
        # {_successor, hops} = Chord.Node.find_successor(node_pid, key)
        # Chord.Node.find_successor_debug(node_pid, key)
        # total_hops = total_hops + hops

        # num_requests =
        #   if num_requests > 0 do
        #     string = Randomizer.randomizer(6)
        #     key = :crypto.hash(:sha, string)
        #     Chord.Node.find_successor_new(node_pid, key)
        #     num_requests - 1
        #   end

        num_requests = num_requests - 1
        string = Randomizer.randomizer(6)
        key = :crypto.hash(:sha, string)
        Chord.Node.find_successor_new(node_pid, key)

        hops =
          receive do
            {:successor, _successor, hops} ->
              # IO.puts("received hops")
              hops
          end

        total_hops = total_hops + hops

        if num_requests == 0 do
          avg_hops = total_hops / total_requests
          send(monitor, {:avg_hops, avg_hops})
          stop(ticker_pid)
          Chord.Node.stop(node_pid)
        end

        run(
          node_pid,
          node_register,
          total_requests,
          num_requests,
          total_hops,
          monitor,
          ticker_pid
        )

      # {:successor, _finger, hops} ->
      #   total_hops = total_hops + hops

      #   if num_requests == 0 do
      #     avg_hops = total_hops / total_requests
      #     # IO.puts("#{inspect(node_pid)} sending avg_hops: #{avg_hops}")
      #     send(monitor, {:avg_hops, avg_hops})
      #     stop(ticker_pid)
      #     Chord.Node.stop(node_pid)
      #   end

      #   run(
      #     node_pid,
      #     node_register,
      #     total_requests,
      #     num_requests,
      #     total_hops,
      #     monitor,
      #     ticker_pid
      #   )

      {:last_tick, _index} ->
        # IO.puts("request_maker stopped")
        :ok

      {:start} ->
        Process.sleep(35000)
        ticker_pid = start(self())

        run(
          node_pid,
          node_register,
          total_requests,
          num_requests,
          total_hops,
          monitor,
          ticker_pid
        )

      {:stop, _reason} ->
        stop(ticker_pid)

        run(
          node_pid,
          node_register,
          total_requests,
          num_requests,
          total_hops,
          monitor,
          ticker_pid
        )
    end
  end
end
