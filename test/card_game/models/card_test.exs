defmodule CardGame.Models.CardTest do
  use ExUnit.Case
  doctest CardGame.Models.Card

  alias CardGame.Models.Card

  describe "new/1 - " do
    test "creates a new card model if all parameters are correct" do
      assert %Card{
               card_val: 13,
               card_str: "KING",
               card_color: "SPADE"
             } =
               Card.new(%{
                 card_val: 13,
                 card_str: "KING",
                 card_color: "SPADE"
               })
    end

    test "returns error if parameters are incorrect" do
      assert {:error, :invalid_card} =
               Card.new(%{
                 card_val: 13
               })
    end
  end
end
