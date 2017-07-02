defmodule Irateburgers.Review do
  @doc """
  A burger review.
  """

  use Ecto.Schema
  alias Irateburgers.Review
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
      cs = %{valid?: true} -> {:ok, Ecto.Changeset.apply_changes(cs)}
      cs -> {:error, cs}
    end
  end

  def changeset(struct, params) do
    struct
    |> Changeset.cast(params, [:id, :username, :rating, :comment, :created_at])
    |> Changeset.validate_required([:id, :username, :rating, :created_at])
  end
end
