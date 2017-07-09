defmodule Irateburgers.Review do
  @moduledoc """
  A burger review.
  """

  use Ecto.Schema
  alias Irateburgers.{ErrorHelpers, Review}
  alias Ecto.Changeset

  @derive {Poison.Encoder, except: [:__meta__]}

  @primary_key false
  embedded_schema do
    field :id, :binary_id
    field :username, :string
    field :rating, :integer
    field :comment, :string
    field :created_at, :utc_datetime
  end
  @type t :: %__MODULE__{}

  @spec new(map | list) ::  {:ok, Review.t} | {:error, term}
  def new(params) do
    case changeset(%Review{}, Map.new(params)) do
      cs = %{valid?: true} -> {:ok, Changeset.apply_changes(cs)}
      cs -> {:error, ErrorHelpers.errors_on(cs)}
    end
  end

  @spec changeset(Review.t, map) :: Changeset.t
  def changeset(struct, params) do
    struct
    |> Changeset.cast(params, __schema__(:fields))
    |> Changeset.validate_required([:id, :username, :rating, :created_at])
  end
end
