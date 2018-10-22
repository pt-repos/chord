defmodule Chord.FingerFixer do
  require Logger

  @fix_interval 1500

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

        # max_hash = :crypto.hash(:sha, Integer.to_string(round(:math.pow(2, m))))

        # {:ok, identifier} = Base.decode16(node_identifier)
        # node_identifier = Base.decode16(node_identifier)
        # IO.puts("node identifier:")
        # IO.inspect(node_identifier)

        next_id =
          :binary.encode_unsigned(
            rem(
              :crypto.bytes_to_integer(node_identifier) + round(:math.pow(2, next)),
              # :crypto.bytes_to_integer(max_hash)
              round(:math.pow(2, 8 * num_bytes))
              # round(:math.pow(2, 8))
            )
          )

        # IO.puts("next_id: #{inspect(next_id)}")
        # IO.puts("next_id")
        # IO.inspect(next_id)
        # IO.inspect(Base.encode16(next_id))
        # IO.puts("m: #{m}, node identifier: #{node_identifier} \nnext_id #{next_id}")
        # IO.puts("FingerFixer")
        {finger, _hops} = Chord.Node.find_successor(node_pid, next_id)
        # IO.puts("next: #{inspect(next)}\n#{inspect(finger)}")
        # IO.puts("finger")
        # IO.inspect(finger)
        finger_table = Map.put(finger_table, next, finger)
        Chord.Node.update_finger_table(node_pid, finger_table)

        # IO.puts(
        #   "#####\n node_pid: #{inspect(node_pid)} \nnext_id: #{inspect(next_id)} \nnext: #{
        #     inspect(next)
        #   } \n#{inspect(finger)} \nfinger_table \n#{inspect(finger_table)}"
        # )

        # Logger.info("finger_table\n#{inspect(finger_table)}")
        # finger_table = List.insert_at(finger_table, next, finger)

        # if Enum.random(1..10) <= 2 do
        #   IO.puts("11111111finger table")
        #   IO.inspect(node_pid)
        #   IO.inspect(finger_table)
        # end

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
