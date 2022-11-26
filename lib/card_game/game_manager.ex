defmodule CardGame.GameManager do
  @moduledoc """
  This module implements the gameplay for card game.
  """

  alias CardGame.GameSupervisor
  alias CardGame.QueueSupervisor

  def play(%{player_id: player_id, player_name: player_name, level: level}),
    do: QueueSupervisor.call_message(level, {:add_player, player_id, player_name})

  def play_turn(%{id: id} = args), do: GameSupervisor.call_message(id, {:play_turn, args})

  def get_player_cards(id, player_id),
    do: GameSupervisor.call_message(id, {:get_player_cards, player_id})
end
