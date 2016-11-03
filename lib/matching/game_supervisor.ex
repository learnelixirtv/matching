defmodule Matching.GameSupervisor do
  alias Matching.Game

  def start_link do
    import Supervisor.Spec

    children = [
      worker(Matching.Game, [])
    ]

    Supervisor.start_link(children, strategy: :simple_one_for_one, name: __MODULE__)
  end

  def find_or_start(game_uid, opts \\ []) do
    case find(game_uid) do
      {_, game, _, _} ->
        game
      _other ->
        opts = Keyword.merge(opts, [uid: game_uid])
        {:ok, game} = Supervisor.start_child(__MODULE__, [opts])
        game
    end
  end

  defp find(game_uid) do
    children = Supervisor.which_children(__MODULE__)
    Enum.find children, fn({_, pid, _, _}) ->
      Game.state(pid).uid == game_uid
    end
  end
end
