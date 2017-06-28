defmodule Irateburgers.BurgerReviewed do
  use Ecto.Schema
  alias Ecto.Changeset
  alias Irateburgers.{Burger, Review, BurgerReviewed}

  @primary_key false
  embedded_schema do
    field :id, :binary_id
    field :burger_id, :binary_id
    field :username, :string
    field :rating, :integer
    field :comment, :string
    field :created_at, :utc_datetime
  end

  def new(params) do
    case changeset(%BurgerReviewed{}, Map.put_new(params, "id", Ecto.UUID.generate())) do
      cs = %{valid?: true} -> {:ok, Ecto.Changeset.apply_changes(cs)}
      cs -> {:error, cs}
    end
  end

  def changeset(struct, params) do
    struct
    |> Changeset.cast(params, [:id, :burger_id, :username, :rating, :comment, :created_at])
    |> Changeset.validate_required([:id, :burger_id, :username, :rating, :created_at])
  end

  def apply(event = %BurgerReviewed{burger_id: id}, burger = %Burger{id: id, reviews: reviews}) do
    review = %Review{
      id: event.id,
      username: event.username,
      rating: event.rating,
      comment: event.comment,
      created_at: event.created_at
    }

    %{burger | reviews: [review | reviews]}
  end
end
