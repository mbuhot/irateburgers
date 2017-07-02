defmodule Irateburgers.Burger do
  use Ecto.Schema
  alias Irateburgers.{Burger, Review}

  @primary_key false
  embedded_schema do
    field :id, :binary_id
    field :version, :integer
    field :name, :string
    field :price, :string
    field :description, :string
    field :images, {:array, :string}
    embeds_many :reviews, Irateburgers.Review
  end

  def serialize(burger = %Burger{}) do
    %{
      id: burger.id,
      name: burger.name,
      price: burger.price,
      description: burger.description,
      images: burger.images,
      reviews: Enum.map(burger.reviews, &Review.serialize/1)
    }
  end

  @doc """
  Find the review for the given burger submitted with the given username.
  Return `nil` if no review found.
  """
  def find_review_by_user(burger = %Burger{}, username) when is_binary(username) do
    Enum.find(burger.reviews, fn review = %Review{} -> review.username == username end)
  end
end
