defmodule Irateburgers.ReviewBurger do
  use Ecto.Schema
  alias Ecto.Changeset
  alias Irateburgers.{Burger, BurgerReviewed, Review, ReviewBurger}

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
    params =
      params
      |> Map.put_new("id", Ecto.UUID.generate())
      |> Map.put_new("created_at", DateTime.utc_now())

    case changeset(%ReviewBurger{}, params) do
      cs = %{valid?: true} -> {:ok, Changeset.apply_changes(cs)}
      cs -> {:error, cs}
    end
  end

  def changeset(struct, params) do
    struct
    |> Changeset.cast(params, [:id, :burger_id, :username, :rating, :comment, :created_at])
    |> Changeset.validate_required([:id, :burger_id, :username, :rating, :comment, :created_at])
  end

  def execute(command = %ReviewBurger{burger_id: burger_id},
              burger = %Burger{id: burger_id, version: n}) when (n > 0) do
    with nil <- Burger.find_review_by_user(burger, command.username) do
      {:ok, event} = BurgerReviewed.new(
        id: command.id,
        burger_id: burger_id,
        version: burger.version + 1,
        username: command.username,
        rating: command.rating,
        comment: command.comment,
        created_at: command.created_at)

      {:ok, [event]}
    else
      %Review{} -> {:error, :user_already_reviewed}
    end
  end
  def execute(command = %ReviewBurger{burger_id: burger_id},
              burger = %Burger{id: burger_id, version: 0}) do
    {:error, :burger_not_found}
  end
end
