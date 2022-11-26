defmodule CardGame.QueueWorker do
  @moduledoc """
  This module implements queue process for card game.
  """

  use GenServer

  alias CardGame.GameSupervisor
  require Logger

  def start_link([%{queue_name: queue_name}]),
    do: GenServer.start_link(__MODULE__, [], name: queue_name)

  @spec init(term()) :: {:ok, map()}
  def init(_init_arg), do: {:ok, %{players: %{}, player_count: 0}}

  def handle_call(
        {:add_player, player_id, name},
        _from,
        %{players: players, player_count: player_count} = state
      ) do
    # IO.inspect([player_count])
    Map.get(players, player_id, false)
    |> case do
      false ->
        {players, player_count, id} =
          players
          |> Map.put(player_id, name)
          |> check_queue_and_start_game(player_count)

        {:reply, {id, "Player added successfully. Please wait for game to start."},
         %{state | players: players, player_count: player_count}}

      _ ->
        {:reply, "Player already exists. Please wait for game to start.", state}
    end
  end

  defp check_queue_and_start_game(players, player_count) when player_count == 2 do
    id = GameSupervisor.start_game(players)
    {%{}, 0, id}
  end

  defp check_queue_and_start_game(players, player_count), do: {players, player_count + 1, nil}
end
