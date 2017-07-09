defmodule Irateburgers.BurgerReviewed do
  @moduledoc """
  Event raised following the `ReviewBurger` command being executed.
  """

  use Ecto.Schema
  alias Ecto.Changeset
  alias Irateburgers.{
    Burger,
    BurgerReviewed,
    ErrorHelpers,
    Event,
    EventProtocol,
    Review
  }

  @primary_key false
  embedded_schema do
    field :id, :integer
    field :review_id, :binary_id
    field :burger_id, :binary_id
    field :version, :integer
    field :username, :string
    field :rating, :integer
    field :comment, :string
    field :created_at, :utc_datetime
  end
  @type t :: %__MODULE__{}

  @spec new(Keyword.t | map) :: {:ok, BurgerReviewed.t} | {:error, term}
  def new(params) do
    case changeset(%BurgerReviewed{}, Map.new(params)) do
      cs = %{valid?: true} -> {:ok, Changeset.apply_changes(cs)}
      cs -> {:error, ErrorHelpers.errors_on(cs)}
    end
  end

  @spec changeset(BurgerReviewed.t, map) :: Ecto.Changeset.t
  def changeset(struct, params) do
    struct
    |> Changeset.cast(params, __schema__(:fields))
    |> Changeset.validate_required(__schema__(:fields) -- [:id])
  end

  defimpl EventProtocol do
    @spec apply(BurgerReviewed.t, Burger.t) :: Burger.t
    def apply(
      event = %BurgerReviewed{burger_id: id, version: m},
      burger = %Burger{id: id, version: n})
    when m == (n + 1)
    do
      {:ok, review} = Review.new(
        id: event.review_id,
        username: event.username,
        rating: event.rating,
        comment: event.comment,
        created_at: event.created_at)

      %{burger | version: event.version, reviews: [review | burger.reviews]}
    end

    @spec to_event_log(BurgerReviewed.t) :: Event.t
    def to_event_log(event = %BurgerReviewed{}) do
      %Event{
        aggregate: event.burger_id,
        sequence: event.version,
        type: to_string(Irateburgers.BurgerReviewed),
        payload: %{
          review_id: event.review_id,
          username: event.username,
          rating: event.rating,
          comment: event.comment,
          created_at: event.created_at
        }
      }
    end
  end

  @spec from_event_log(Event.t) :: BurgerReviewed.t
  def from_event_log(event = %Event{}) do
    {:ok, domain_event} =
      BurgerReviewed.new(
        Map.merge(
          event.payload,
          %{
            "id" => event.id,
            "burger_id" => event.aggregate,
            "version" => event.sequence
          }))

    domain_event
  end
end
