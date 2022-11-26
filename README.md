# CardGame

This is a simple card game architecture in elixir.

## Project INFO

1) To eun the test cases run mix test --seed 0

Steps to run the game manually:

1) run the iex shell with command 
    - iex -S mix

2) on the iex shell fire 
    - alias CardGame 
  
3) now to add a new player fire command
    - CardGame.play(%{player_id: 1, player_name: "john", level: "1"}) 

   change the player id accordingly to add new players

4) to get cards alloted to a player use command
    - CardGame.get_player_cards(id, player_id)

    Here id is the id of the game on which players are playing. You will get the id of the game in response  when a third player joins the game. player_id is the id of the player.

5) to play a turn
    - CardGame.play_turn(%{
      id: game_id,
      player_id: player_id,
      card_val: card_val
    })

    Here id id the id of the game on which players are playing. You will get the id of the game in response  when a third player joins the game. player_id is the id of the player.
    card_val id the card_val parameter received from step 4.

8) After 8 rounds are finished winners are declared and the game is reinitialised with the
same game id.

