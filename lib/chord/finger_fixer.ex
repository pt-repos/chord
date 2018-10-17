defmodule Chord.FingerFixer do
  @fix_interval 5000

  def start(pid) do
    Chord.Ticker.start(pid, @fix_interval)
  end

  def stop(pid) do
    Chord.Ticker.stop(pid)
  end

  def run(node_identifier, node_pid, finger_table, next, m, ticker_pid) do
    receive do
      {:tick, _index} ->
        next = next + 1

        next =
          if next > m do
            1
          else
            next
          end

        next_id =
          :binary.encode_unsigned(
            rem(
              :crypto.bytes_to_integer(node_identifier) + :math.pow(2, next - 1),
              :math.pow(2, m)
            )
          )

        finger = Chord.Node.find_successor(node_pid, next_id)
        finger_table = List.insert_at(finger_table, next, finger)
        run(node_identifier, node_pid, finger_table, next, m, ticker_pid)

      {:last_tick, _index} ->
        :ok

      {:start, finger_table, next, m} ->
        ticker_pid = start(self())
        run(node_identifier, node_pid, finger_table, next, m, ticker_pid)

      {:stop, _reason} ->
        stop(ticker_pid)
        run(node_identifier, node_pid, finger_table, next, m, ticker_pid)
    end
  end
end
