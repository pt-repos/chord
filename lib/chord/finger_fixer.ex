defmodule Chord.FingerFixer do
  require Logger

  @fix_interval 100

  def start(pid) do
    # IO.puts("starting ticker")
    Chord.Ticker.start(pid, @fix_interval)
  end

  def stop(pid) do
    Chord.Ticker.stop(pid)
  end

  # TODO: handle mod
  def run(node_identifier, node_pid, finger_table, next, m, num_bytes, ticker_pid) do
    receive do
      {:tick, _index} ->
        next = next + 1

        next =
          if next >= m do
            0
          else
            next
          end

        next_id =
          :binary.encode_unsigned(
            rem(
              :crypto.bytes_to_integer(node_identifier) + round(:math.pow(2, next)),
              # :crypto.bytes_to_integer(max_hash)
              round(:math.pow(2, 8 * num_bytes))
              # round(:math.pow(2, 8))
            )
          )

        Chord.Node.find_successor_new(node_pid, next_id)

        finger =
          receive do
            {:successor, finger, _hops} ->
              # IO.puts("received finger")
              finger
          end

        finger_table = Map.put(finger_table, next, finger)
        Chord.Node.update_finger_table(node_pid, finger_table)

        # IO.puts(
        #   "#####\n node_pid: #{inspect(node_pid)} \nnext_id: #{inspect(next_id)} \nnext: #{
        #     inspect(next)
        #   } \n#{inspect(finger)} \nfinger_table \n#{inspect(finger_table)}"
        # )

        run(node_identifier, node_pid, finger_table, next, m, num_bytes, ticker_pid)

      {:last_tick, _index} ->
        # IO.puts("finger_fixer stopped")
        :ok

      {:start} ->
        ticker_pid = start(self())
        run(node_identifier, node_pid, finger_table, next, m, num_bytes, ticker_pid)

      {:stop, _reason} ->
        stop(ticker_pid)
        run(node_identifier, node_pid, finger_table, next, m, num_bytes, ticker_pid)
    end
  end
end
