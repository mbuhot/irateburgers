defmodule Irateburgers.BurgerReviewed do
  use Ecto.Schema
  alias Ecto.Changeset
  alias Irateburgers.{Burger, Event, Review, BurgerReviewed}

  @primary_key false
  embedded_schema do
    field :id, :binary_id
    field :burger_id, :binary_id
    field :version, :integer
    field :username, :string
    field :rating, :integer
    field :comment, :string
    field :created_at, :utc_datetime
  end

  def new(params) do
    case changeset(%BurgerReviewed{}, Map.new(params)) do
      cs = %{valid?: true} -> {:ok, Ecto.Changeset.apply_changes(cs)}
      cs -> {:error, cs}
    end
  end

  def changeset(struct, params) do
    struct
    |> Changeset.cast(params, [:id, :burger_id, :version, :username, :rating, :comment, :created_at])
    |> Changeset.validate_required([:id, :burger_id, :version, :username, :rating, :created_at])
  end

  def apply(event = %BurgerReviewed{burger_id: id, version: m},
            burger = %Burger{id: id, version: n, reviews: reviews}) when m == (n+1) do
    {:ok, review} = Review.new(
      id: event.id,
      username: event.username,
      rating: event.rating,
      comment: event.comment,
      created_at: event.created_at)

    %{burger | version: event.version, reviews: [review | reviews]}
  end

  def to_eventlog(event = %BurgerReviewed{}) do
    %Event{
      aggregate: event.burger_id,
      sequence: event.version,
      type: to_string(__MODULE__),
      payload: %{
        id: event.id,
        username: event.username,
        rating: event.rating,
        comment: event.comment,
        created_at: event.created_at
      }
    }
  end

  def from_event_log(event = %Event{}) do
    {:ok, domain_event} =
      BurgerReviewed.new(
        Map.merge(
          event.payload,
          %{"burger_id" => event.aggregate, "version" => event.sequence}))

    domain_event
  end
end
