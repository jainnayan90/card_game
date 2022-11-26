defmodule CardGame do
  @moduledoc """
  This module implements the public api for card game.
  """
  alias CardGame.GameManager

  defdelegate play(player_info), to: GameManager

  defdelegate play_turn(args), to: GameManager

  defdelegate get_player_cards(id, player_id), to: GameManager
end
