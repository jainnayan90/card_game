defmodule CardGame.GameWorker do
  @moduledoc """
  This module implements all the game logic for card game.
  """

  use GenServer

  alias CardGame.ActiveGameMap
  alias CardGame.GameSupervisor
  alias CardGame.Models.Card

  require Logger

  def start_link([%{id: id}] = opts) do
    GenServer.start_link(__MODULE__, opts, name: GameSupervisor.via_tuple(id))
  end

  @impl true
  @spec init(term()) :: {:ok, map()}
  def init([%{id: id, players: players, agent_pid: agent_pid}]) do
    state = initialise_game(id, agent_pid, players)
    {:ok, state}
  end

  @impl true
  def handle_call({:play_turn, args}, _from, state) do
    %{
      id: id,
      player_id: player_id,
      card_val: card_val
    } = args

    with ^id <- Map.get(state, :id, :invalid_game_id),
         {:ok, player} <- check_player_exists(player_id, state),
         {:ok, card, player_cards} <- check_played_card(card_val, player.player_cards),
         {:ok, state, result} <- play_turn(player, card, player_cards, state) do
      case check_for_winner(state) do
        :no_winner ->
          {:reply, {:ok, result}, state}

        {:ok, winners} ->
          state = initialise_game(state.id, state.agent_pid, state.original_players)
          {:reply, {:ok, {:round_finished, winners}}, state}
      end
    else
      {:error, error} ->
        {:reply, {:error, error}, state}

      false ->
        {:reply, {:error, "Invalid game id."}, state}

      _ ->
        {:reply, {:error, "Unknown error."}, state}
    end
  end

  @impl true
  def handle_call({:get_player_cards, player_id}, _from, state) do
    players = state.players

    case get_player_cards(players, player_id) do
      {:error, error} ->
        {:reply, {:error, error}, state}

      cards ->
        {:reply, {:ok, cards}, state}
    end
  end

  defp get_player_cards([], _player_id), do: {:error, :invalid_user}

  defp get_player_cards([%{player_id: id} = player | r], player_id) do
    case id do
      ^player_id ->
        player.player_cards

      _ ->
        get_player_cards(r, player_id)
    end
  end

  defp initialise_game(id, agent_pid, players) do
    deck = prepare_deck()
    {deck, player_cards} = get_player_cards(deck, [], 8)
    {_deck, bot_cards} = get_player_cards(deck, [], 8)

    players1 =
      Enum.map(players, fn {k, v} ->
        ActiveGameMap.put(agent_pid, k, id)

        %{
          player_id: k,
          name: v,
          rounds_played: [],
          player_cards: player_cards,
          bot_cards: bot_cards
        }
      end)

    %{
      id: id,
      players: players1,
      current_round: 1,
      turns_played: 0,
      original_players: players,
      agent_pid: agent_pid
    }
  end

  defp get_winners([], winners, _), do: winners

  defp get_winners([{_, _, count} = res | r], [], _) do
    get_winners(r, [res], count)
  end

  defp get_winners([{_, _, winnings} = res | r], winners, max_count) do
    cond do
      winnings == max_count ->
        get_winners(r, winners ++ [res], max_count)

      winnings > max_count ->
        get_winners(r, [res], winnings)

      winnings < max_count ->
        get_winners(r, winners, max_count)
    end
  end

  defp get_player_result(player) do
    rounds_played = player.rounds_played

    {player.player_id, player.name,
     Enum.sum(Enum.map(rounds_played, fn {_, _, _, res} -> res end))}
  end

  defp check_for_winner(state) when state.current_round == 9 do
    results = Enum.map(state.players, &get_player_result/1)
    {:ok, get_winners(results, [], 0)}
  end

  defp check_for_winner(_), do: :no_winner

  defp check_player(_, []), do: {:error, :invalid_player_id}

  defp check_player(player_id, [player | r]) do
    player
    |> Map.get(:player_id, false)
    |> case do
      ^player_id ->
        {:ok, player}

      _ ->
        check_player(player_id, r)
    end
  end

  defp check_player_exists(player_id, %{players: players}), do: check_player(player_id, players)

  defp get_card_index(_, [], _), do: {:error, :invalid_card}

  defp get_card_index(player_val, [%Card{card_val: card_val} | r], index) do
    case card_val do
      ^player_val ->
        {:ok, index}

      _ ->
        get_card_index(player_val, r, index + 1)
    end
  end

  defp check_played_card(card_val, player_cards) do
    case get_card_index(card_val, player_cards, 0) do
      {:error, :invalid_card} ->
        {:error, :invalid_card}

      {:ok, index} ->
        {card, player_cards} = List.pop_at(player_cards, index)
        {:ok, card, player_cards}
    end
  end

  defp get_card_color(card_val) when card_val <= 13, do: "Spade"
  defp get_card_color(card_val) when card_val <= 26, do: "Club"
  defp get_card_color(card_val) when card_val <= 39, do: "Heart"
  defp get_card_color(card_val) when card_val <= 52, do: "Diamond"

  defp get_card_str(card_val) when rem(card_val, 13) == 1, do: "ACE"
  defp get_card_str(card_val) when rem(card_val, 13) == 11, do: "JACK"
  defp get_card_str(card_val) when rem(card_val, 13) == 12, do: "QUEEN"
  defp get_card_str(card_val) when rem(card_val, 13) == 0, do: "KING"
  defp get_card_str(card_val) when rem(card_val, 13) <= 10, do: to_string(rem(card_val, 13))

  defp get_player_cards(deck, player_cards, 0), do: {deck, player_cards}

  defp get_player_cards(deck, player_cards, num) do
    card_index = Enum.random(0..(length(deck) - 1))
    {card, deck} = List.pop_at(deck, card_index)
    get_player_cards(deck, player_cards ++ [card], num - 1)
  end

  defp play_turn(player, player_card, player_cards, state) do
    current_round = state.current_round
    player_rounds = player.rounds_played

    case List.keyfind(player_rounds, current_round, 0) do
      nil ->
        result_str = ["You won this hand.!!", "You lost this hand!!"]
        result = Enum.random([0, 1])
        {bot_cards, [bot_card]} = get_player_cards(player.bot_cards, [], 1)
        player_rounds = player_rounds ++ [{current_round, player_card, bot_card, result}]

        state =
          player
          |> Map.put(:rounds_played, player_rounds)
          |> Map.put(:bot_cards, bot_cards)
          |> Map.put(:player_cards, player_cards)
          |> update_state_turn(state)

        {:ok, state, Enum.at(result_str, result)}

      _ ->
        {:error, :turn_already_played}
    end
  end

  defp update_state_turn(%{player_id: player_id} = player, state) do
    players =
      Enum.map(state.players, fn splayer ->
        case splayer.player_id do
          ^player_id ->
            player

          _ ->
            splayer
        end
      end)

    {turns_played, next_round} = get_current_round(state.turns_played + 1, state.current_round)

    %{state | players: players, turns_played: turns_played, current_round: next_round}
  end

  defp get_current_round(turns_played, current_round) when turns_played == 3,
    do: {0, current_round + 1}

  defp get_current_round(turns_played, current_round), do: {turns_played, current_round}

  defp prepare_deck() do
    cards = Enum.to_list(1..52)

    Enum.map(cards, fn card_val ->
      card_color = get_card_color(card_val)
      card_str = get_card_str(card_val)
      %Card{card_val: card_val, card_color: card_color, card_str: card_str}
    end)
  end
end
