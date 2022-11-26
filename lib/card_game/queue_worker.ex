defmodule CardGame.QueueWorker do
  @moduledoc """
  This module implements queue process for card game.
  """

  use GenServer

  alias CardGame.ActiveGameMap
  alias CardGame.GameSupervisor

  require Logger

  def start_link([%{queue_name: queue_name}] = args),
    do: GenServer.start_link(__MODULE__, args, name: queue_name)

  @spec init(term()) :: {:ok, map()}
  def init([%{agent_pid: agent_pid}]),
    do: {:ok, %{players: %{}, player_count: 0, agent_pid: agent_pid}}

  def handle_call(
        {:add_player, player_id, name},
        _from,
        %{players: players, player_count: player_count, agent_pid: agent_pid} = state
      ) do
    Map.get(players, player_id, false)
    |> case do
      false ->
        if ActiveGameMap.get(agent_pid, player_id) != nil do
          {:reply, {:error, "Player already playing a different game."}, state}
        else
          {players, player_count, id} =
            players
            |> Map.put(player_id, name)
            |> check_queue_and_start_game(player_count, agent_pid)

          {:reply, {id, "Player added successfully. Please wait for game to start."},
           %{state | players: players, player_count: player_count}}
        end

      _ ->
        {:reply, "Player already exists. Please wait for game to start.", state}
    end
  end

  defp check_queue_and_start_game(players, player_count, agent_pid) when player_count == 2 do
    id = GameSupervisor.start_game(players, agent_pid)
    {%{}, 0, id}
  end

  defp check_queue_and_start_game(players, player_count, _), do: {players, player_count + 1, nil}
end
