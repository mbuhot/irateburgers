defmodule Irateburgers.ReviewBurger do
  use Ecto.Schema
  alias Ecto.Changeset
  alias Irateburgers.{Burger, BurgerReviewed, CommandProtocol, ErrorHelpers, Review, ReviewBurger}

  @primary_key false
  embedded_schema do
    field :review_id, :binary_id
    field :burger_id, :binary_id
    field :username, :string
    field :rating, :integer
    field :comment, :string
    field :created_at, :utc_datetime
  end

  def new(params) do
    case changeset(%ReviewBurger{}, Map.new(params)) do
      cs = %{valid?: true} -> {:ok, Changeset.apply_changes(cs)}
      cs -> {:error, ErrorHelpers.errors_on(cs)}
    end
  end

  def changeset(struct, params) do
    struct
    |> Changeset.cast(params, [:burger_id, :username, :rating, :comment])
    |> Changeset.put_change(:review_id, Ecto.UUID.generate())
    |> Changeset.put_change(:created_at, DateTime.utc_now())
    |> Changeset.validate_required([:review_id, :burger_id, :username, :rating, :comment, :created_at])
  end

  defimpl CommandProtocol do
    def execute(command = %ReviewBurger{burger_id: burger_id},
                burger = %Burger{id: burger_id, version: n}) when (n > 0) do
      with nil <- Burger.find_review_by_user(burger, command.username) do
        {:ok, event} = BurgerReviewed.new(
          review_id: command.review_id,
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
    def execute(%ReviewBurger{burger_id: burger_id}, %Burger{id: burger_id, version: 0}) do
      {:error, :burger_not_found}
    end
  end
end
