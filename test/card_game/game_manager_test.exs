defmodule CardGame.GameManagerTest do
  use ExUnit.Case, async: false
  doctest CardGame.GameManager

  alias CardGame.GameManager
  alias CardGame.GameSupervisor

  setup_all do
    player1 = %{player_id: 4, player_name: "john", level: "1"}
    player2 = %{player_id: 5, player_name: "foo", level: "1"}
    player3 = %{player_id: 6, player_name: "bar", level: "1"}
    {nil, _res} = GameManager.play(player1)
    {nil, _res} = GameManager.play(player2)
    {game_id, _res} = GameManager.play(player3)

    {:ok, player1_cards} = GameManager.get_player_cards(game_id, player1.player_id)
    {:ok, player2_cards} = GameManager.get_player_cards(game_id, player2.player_id)
    {:ok, player3_cards} = GameManager.get_player_cards(game_id, player3.player_id)

    player1 = Map.put(player1, :cards, player1_cards)
    player2 = Map.put(player2, :cards, player2_cards)
    player3 = Map.put(player3, :cards, player3_cards)
    %{game_id: game_id, player1: player1, player2: player2, player3: player3}
  end

  describe "game manager - add player - " do
    test "add player to a game queue successfully." do
      {nil, res} = GameManager.play(%{player_id: 1, player_name: "john", level: "1"})
      assert "Player added successfully. Please wait for game to start." = res
    end

    test "gives error if the player is already added to the queue." do
      {nil, res} = GameManager.play(%{player_id: 2, player_name: "foo", level: "1"})
      assert "Player added successfully. Please wait for game to start." = res
      res1 = GameManager.play(%{player_id: 2, player_name: "john", level: "1"})
      assert "Player already exists. Please wait for game to start." = res1
    end

    test "a new game process is started when three users join." do
      {game_id, res} = GameManager.play(%{player_id: 3, player_name: "bar", level: "1"})
      assert "Player added successfully. Please wait for game to start." = res

      assert game_id != nil

      games = GameSupervisor.get_children()
      {:ok, player1_cards} = GameManager.get_player_cards(game_id, 3)

      assert 8 = length(player1_cards)
      assert 2 = length(games)
    end
  end

  describe "game manager - play turn - " do
    test "player1 plays the turn.", %{game_id: game_id, player1: player1} do
      {_player1, res} = play_turn(game_id, player1)
      assert {:ok, _} = res
    end

    test "returns error if a player plays already played card", %{
      game_id: game_id,
      player1: player1
    } do
      {_player1, res} = play_turn(game_id, player1)
      assert {:error, :invalid_card} = res
    end

    test "returns error if player2 plays two consecutive turns.", %{
      game_id: game_id,
      player2: player2
    } do
      {player2, res} = play_turn(game_id, player2)
      assert {:ok, _} = res

      {_player2, res1} = play_turn(game_id, player2)
      assert {:error, :turn_already_played} = res1
    end

    test "proceeds to next round if all the players play their turn.", %{
      game_id: game_id,
      player3: player3
    } do
      {_player3, res} = play_turn(game_id, player3)
      assert {:ok, _} = res
    end

    test "winner is declared after 8 rounds", %{
      game_id: game_id,
      player1: player1,
      player2: player2,
      player3: player3
    } do
      rounds_left = Enum.to_list(1..7)

      Enum.each(rounds_left, fn round ->
        {_player1, res1} = play_turn(game_id, player1, round)
        assert {:ok, _} = res1

        {_player2, res2} = play_turn(game_id, player2, round)
        assert {:ok, _} = res2

        {_player3, res3} = play_turn(game_id, player3, round)

        case round do
          7 ->
            assert {:ok, {:round_finished, _}} = res3

          _ ->
            assert {:ok, _} = res3
        end
      end)
    end

    test "a new game of 8 rounds is re-started this game is finished", %{
      game_id: game_id,
      player1: player1
    } do
      {:ok, player1_cards} = GameManager.get_player_cards(game_id, player1.player_id)
      player1 = %{player1 | cards: player1_cards}
      {_player1, res} = play_turn(game_id, player1)
      assert {:ok, _} = res
    end
  end

  defp play_turn(game_id, player, card_index \\ 0) do
    {card, rest} = List.pop_at(player.cards, card_index)
    player = Map.put(player, :cards, rest)

    info = %{
      id: game_id,
      player_id: player.player_id,
      card_val: card.card_val
    }

    {player, GameManager.play_turn(info)}
  end
end
