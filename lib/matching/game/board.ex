defmodule Matching.Game.Board do
  require Integer

  alias Matching.Matrix

  @type coords :: list

  @spec new(integer, integer) :: Matrix.t
  def new(width, height) when Integer.is_even(width * height) do
    deck =
      for suit <- ~w(C D H S), face <- Enum.concat(2..10, ~w(J Q K A)) do
        "#{face}#{suit}"
      end

    number = round((width * height) / 2)

    cards = Enum.take_random(deck, number)
    cards
    |> Enum.concat(cards)
    |> Enum.shuffle
    |> Enum.chunk(width)
    |> Matrix.from_list
  end
  def new(width, height) when is_integer(width) and is_integer(height) do
    raise ArgumentError, """
    width and height must multiply to an even number.

      width = #{inspect(width)}
      height = #{inspect(height)}

    width * height = #{inspect(width * height)}
    """
  end

  @doc """
  Checks if the cards at two coordinates are a match or not.
  """
  @spec match?(Matrix.t, coords, coords) :: boolean
  def match?(board, a, b) do
    get_in(board, a) == get_in(board, b)
  end

  @doc """
  Checks if there are still any cards on the board. Useful for determining
  if the game is over.
  """
  def empty?(board) do
    board
    |> Matrix.to_list
    |> List.flatten
    |> Enum.all?(&(&1 == nil))
  end

  @doc """
  Removes a card from a given coordinate by putting nil there.
  """
  @spec remove(Matrix.t, coords) :: Matrix.t
  def remove(board, coords) do
    put_in(board, coords, nil)
  end
end
