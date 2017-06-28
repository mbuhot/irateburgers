defmodule Irateburgers.Burger do
  use Ecto.Schema
  alias Irateburgers.{Burger, Review}

  @primary_key {:id, :binary_id, autogenerate: false}
  embedded_schema do
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

  def apply_events(burger = %Burger{}, events) when is_list(events) do
    Enum.reduce(events, burger, fn event, burger ->
      event.__struct__.apply(event, burger)
    end)
  end
end
