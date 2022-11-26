defmodule CardGame.Models.Card do
  @moduledoc """
  This module represents a simple card.
  """

  @enforce_keys [
    :card_val,
    :card_color,
    :card_str
  ]

  defstruct [
    :card_val,
    :card_color,
    :card_str
  ]

  @type t :: %__MODULE__{
          card_val: integer(),
          card_color: String.t(),
          card_str: String.t()
        }

  @spec new(%{
          card_val: integer(),
          card_color: String.t(),
          card_str: String.t()
        }) :: CardGame.Models.Card.t() | {:error, atom()}
  def new(%{
        card_val: card_val,
        card_str: card_str,
        card_color: card_color
      }) do
    %__MODULE__{
      card_val: card_val,
      card_str: card_str,
      card_color: card_color
    }
  end

  def new(_) do
    {:error, :invalid_card}
  end
end
