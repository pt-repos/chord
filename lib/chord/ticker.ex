defmodule Chord.Ticker do
  def start(recipient_pid, tick_interval, duration \\ :infinity) do
    ticker_pid = spawn(__MODULE__, :loop, [recipient_pid, tick_interval, 0])
    send(self(), :send_tick)
    schedule_terminate(ticker_pid, duration)
    ticker_pid
  end

  def stop(ticker_pid) do
    send(ticker_pid, :terminate)
  end

  def loop(recipient_pid, tick_interval, current_index) do
    receive do
      :send_tick ->
        send(recipient_pid, {:tick, current_index})
        Process.send_after(self(), :send_tick, tick_interval)
        loop(recipient_pid, tick_interval, current_index + 1)

      :terminate ->
        :ok
        send(recipient_pid, {:last_tick, current_index})
    end
  end

  defp schedule_terminate(_pid, :infinity), do: :ok

  defp schedule_terminate(ticker_pid, duration),
    do: Process.send_after(ticker_pid, :terminate, duration)
end
