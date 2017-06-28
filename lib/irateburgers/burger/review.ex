defmodule Irateburgers.Review do
  use Ecto.Schema
  alias Irateburgers.Review

  @primary_key {:id, :binary_id, autogenerate: false}
  embedded_schema do
    field :username, :string
    field :rating, :integer
    field :comment, :string
    field :created_at, :utc_datetime
  end

  def serialize(review = %Review{}) do
    %{
      id: review.id,
      username: review.username,
      rating: review.rating,
      comment: review.comment,
      created_at: review.created_at
    }
  end
end
