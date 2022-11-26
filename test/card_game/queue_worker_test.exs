defmodule CardGame.QueueWorkerTest do
  use ExUnit.Case
  doctest CardGame.QueueWorker

  describe "Queue worker - " do
    test "checks queue worker process has started" do
      is_alive =
        get_queue_name("1")
        |> Process.whereis()
        |> Process.alive?()

      assert true = is_alive
    end
  end

  defp get_queue_name(queue_level),
    do: String.to_atom("CardGame.QueueWorker" <> "_" <> queue_level)
end
