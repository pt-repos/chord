defmodule Chord.FingerFixer do
  require Logger

  @fix_interval 100

  def start(pid) do
    Chord.Ticker.start(pid, @fix_interval)
  end

  def stop(pid) do
    Chord.Ticker.stop(pid)
  end

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
              round(:math.pow(2, 8 * num_bytes))
            )
          )

        Chord.Node.find_successor(node_pid, next_id)

        finger =
          receive do
            {:successor, finger, _hops} ->
              finger
          end

        finger_table = Map.put(finger_table, next, finger)
        Chord.Node.update_finger_table(node_pid, finger_table)

        run(node_identifier, node_pid, finger_table, next, m, num_bytes, ticker_pid)

      {:last_tick, _index} ->
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
