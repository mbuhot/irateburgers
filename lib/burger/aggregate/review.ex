defmodule Irateburgers.Review do
  @doc """
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

  def new(params) do
    case changeset(%Review{}, Map.new(params)) do
      cs = %{valid?: true} -> {:ok, Changeset.apply_changes(cs)}
      cs -> {:error, ErrorHelpers.errors_on(cs)}
    end
  end

  def changeset(struct, params) do
    struct
    |> Changeset.cast(params, __schema__(:fields))
    |> Changeset.validate_required([:id, :username, :rating, :created_at])
  end
end
