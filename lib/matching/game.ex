defmodule Matching.Game do
  use GenServer

  import Destructure

  alias Matching.Game.{
    State,
    Event
  }

  def add_player(game, player_name) do
    GenServer.call(game, {:add_player, player_name})
  end

  def reveal(game, coords) do
    GenServer.call(game, {:reveal, coords})
  end

  def check_match(game, player_name, coord_a, coord_b) do
    GenServer.call(game, {:check_match, player_name, coord_a, coord_b})
  end

  def state(game) do
    GenServer.call(game, :state)
  end

  ###
  # GenServer API
  ###

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    defaults = [
      uid: :erlang.system_time(:seconds),
      num_players: 2,
      width: 10,
      height: 2
    ]

    opts = Keyword.merge(defaults, opts)

    %{
      uid: opts[:uid],
      num_players: opts[:num_players],
      players: [],
      board: Board.new(opts[:width], opts[:height])
    }
  end

  def handle_call({:add_player, player_name}, _from, d(%{players, num_players}) = state)
  when length(players) < num_players do
    player = %{name: player_name, score: 0, current_turn: false}
    state = %{state | players: [player|state.players]}
    {:reply, {:ok, state}, state}
  end
  def handle_call({:add_player, _player_name}, _from, state) do
    {:reply, {:error, "Game already has #{state.num_players} players."}}
  end

  def handle_call({:reveal, [x, y] = coords}, _from, state) do
    case get_in(state.board[x][y]) do
      nil ->
        {:reply, {:error, "No card at position #{x}, #{y}"}, state}
      card ->
        Event.sync_notify({state.uid, :reveal, coords, card})
        {:reply, {:ok, card}, state}
    end
  end

  def handle_call({:check_match, player_name, coord_a, coord_b}, _from, state) do
    player = Enum.find(state.players, &(&1.name == player_name && &1.current_turn))
    index = Enum.find_index(state.players, &(&1 == player))

    cond do
      player && Board.match?(state.board, coord_a, coord_b) ->
        state =
          state
          |> remove_match(coord_a, coord_b)
          |> increment_player_score(player)
          |> next_turn
          |> finish

        reply({:match, state}, state)

      is_map(player) ->
        state = next_turn(state)
        reply({:no_match, state}, state)

      true ->
        {:reply, {:error, "Player not found"}, state}
    end
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  ###
  # Private API
  ###

  defp reply(state, response) do
    Event.sync_notify({state.uid, response})
    {:reply, response, state}
  end

  defp remove_match(state, coord_a, coord_b) do
    Map.update! state, :board, fn(board) ->
      board
      |> Board.remove(coord_a)
      |> Board.remove(coord_b)
    end
  end

  defp increment_player_score(state, player) do
    index = Enum.find_index(state.players, &(&1 == player))
    get_and_update_in(state, [:players, Access.at(index), :score], &(&1 + 1))
  end

  def next_turn(d(%{players, num_players}) = state)
  when length(players) == num_players do
    current_player_index = Enum.find_index(state.players, &(&1.current_turn)) || -1
    next_player_index =
      if current_player_index == length(state.players) do
        0
      else
        current_player_index + 1
      end

    # TODO: Notify next player that it is their turn

    players =
      state.players
      |> List.update_at(current_player_index, &(%{&1 | current_turn: false}))
      |> List.update_at(next_player_index, &(%{&1 | current_turn: true}))

    %{state | players: players}
  end
  def next_turn(state), do: state

  defp finish(state) do
    if Board.empty?(state.board) do
      # TODO: finish the game
    else
      state
    end
  end
end
