defmodule Chord.Stabilizer do
  require Logger

  @stabilize_interval 5

  def start(pid) do
    Chord.Ticker.start(pid, @stabilize_interval)
  end

  def stop(pid) do
    Chord.Ticker.stop(pid)
  end

  def run(node_identifier, node_pid, successor, ticker_pid) do
    receive do
      {:tick, _index} ->
        s_predecessor = Chord.Node.get_predecessor(successor[:pid])

        new_successor =
          if is_nil(s_predecessor) do
            successor
          else
            if Chord.IntervalChecker.check_open_interval(
                 s_predecessor[:identifier],
                 node_identifier,
                 successor[:identifier]
               ) do
              s_predecessor
            else
              successor
            end
          end

        Chord.Node.update_successor(node_pid, new_successor)
        Chord.Node.notify(new_successor[:pid], identifier: node_identifier, pid: node_pid)

        run(node_identifier, node_pid, new_successor, ticker_pid)

      {:last_tick, _index} ->
        :ok

      {:start, successor} ->
        ticker_pid = start(self())

        run(node_identifier, node_pid, successor, ticker_pid)

      {:stop, _reason} ->
        stop(ticker_pid)

        run(node_identifier, node_pid, successor, ticker_pid)
    end
  end
end
