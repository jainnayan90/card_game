defmodule CardGame.QueueSupervisorTest do
  use ExUnit.Case
  doctest CardGame.QueueSupervisor

  @supervisor_name :"Elixir.CardGame.QueueSupervisor"

  describe "queue_supervisor - " do
    test "check supervisor process is started" do
      is_alive =
        @supervisor_name
        |> Process.whereis()
        |> Process.alive?()

      assert true = is_alive
    end
  end
end
