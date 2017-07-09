defmodule Irateburgers.ReviewBurger do
  @moduledoc """
  Command to add a review to a burger.
  A single user can not review a burger more than once.
  The burger must already exist in the system before it can be reviewed.
  """

  use Ecto.Schema
  alias Ecto.{Changeset, UUID}
  alias Irateburgers.{
    Burger,
    BurgerReviewed,
    CommandProtocol,
    ErrorHelpers,
    Review,
    ReviewBurger
  }

  @primary_key false
  embedded_schema do
    field :review_id, :binary_id
    field :burger_id, :binary_id
    field :username, :string
    field :rating, :integer
    field :comment, :string
    field :created_at, :utc_datetime
  end
  @type t :: %__MODULE__{}

  @spec new(Keyword.t | map) :: {:ok, ReviewBurger.t} | {:error, term}
  def new(params) do
    case changeset(%ReviewBurger{}, Map.new(params)) do
      cs = %{valid?: true} -> {:ok, Changeset.apply_changes(cs)}
      cs -> {:error, ErrorHelpers.errors_on(cs)}
    end
  end

  @spec changeset(ReviewBurger.t, map) :: Changeset.t
  def changeset(struct, params) do
    struct
    |> Changeset.cast(params, [:burger_id, :username, :rating, :comment])
    |> Changeset.put_change(:review_id, UUID.generate())
    |> Changeset.put_change(:created_at, DateTime.utc_now())
    |> Changeset.validate_required(__schema__(:fields))
  end

  defimpl CommandProtocol do
    @spec execute(ReviewBurger.t, Burger.t) :: {:ok, [BurgerReviewed.t]} | {:error, term}
    def execute(
      command = %ReviewBurger{burger_id: burger_id},
      burger = %Burger{id: burger_id, version: n})
    when (n > 0) do
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
    def execute(
      %ReviewBurger{burger_id: burger_id},
      %Burger{id: burger_id, version: 0})
    do
      {:error, :burger_not_found}
    end
  end
end
