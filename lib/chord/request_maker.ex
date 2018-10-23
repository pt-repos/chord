defmodule Chord.RequestMaker do
  @request_interval 1000

  def start(pid) do
    Chord.Ticker.start(pid, @request_interval)
  end

  def stop(pid) do
    Chord.Ticker.stop(pid)
  end

  def run(node_pid, node_register, total_requests, num_requests, total_hops, monitor, ticker_pid) do
    receive do
      {:tick, _index} ->
        num_requests = num_requests - 1
        string = Randomizer.randomizer(6)
        key = :crypto.hash(:sha, string)
        Chord.Node.find_successor(node_pid, key)

        hops =
          receive do
            {:successor, _successor, hops} ->
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

      {:last_tick, _index} ->
        :ok

      {:start} ->
        Process.sleep(10000)
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
