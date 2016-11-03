# Matching

1. Player visits URL of ReactJS SPA
2. Click button to "Start New Game"
3. Redirects to a unique URL with a generated UID for the game.
4. Ask for player's name.
5. Join Phoenix channel with the topic `game:uid`, with `{player_name: 'name'}`. Receive either a `{:ok, :player, game_state}` message or an `{:ok, :spectator, game_state}` message if the game is already full.
    - Channel finds or starts a game with the uid
6. Broadcast `{:turn, player_name}` message on channel to indicate whose turn it is.
7. Player selects 1 card. Sends a `{:reveal, coords}` message to the channel. Channel responds with `{:revealed, coords, face}` message.
8. Player selects another card. Repeat #7.
9. Send `{:play, player_name, coord_a, coord_b}` message to see if cards match. Wait for message.
10. Server sends confirmation on whether cards matched, incremented score, etc.
11. Next turn. Repeat until board is empty.
12. When board is empty, server sends `:game_over` message which terminates the game, and declares a winner.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `matching` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:matching, "~> 0.1.0"}]
    end
    ```

  2. Ensure `matching` is started before your application:

    ```elixir
    def application do
      [applications: [:matching]]
    end
    ```
