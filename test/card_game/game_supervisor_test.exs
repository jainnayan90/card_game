defmodule CardGame.GameSupervisorTest do
  use ExUnit.Case
  doctest CardGame.GameSupervisor

  @supervisor_name :"Elixir.CardGame.GameSupervisor"

  describe "game_supervisor - " do
    test "check supervisor process is started" do
      is_alive =
        @supervisor_name
        |> Process.whereis()
        |> Process.alive?()

      assert true = is_alive
    end
  end
end
