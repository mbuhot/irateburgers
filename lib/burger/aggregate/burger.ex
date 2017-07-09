defmodule Irateburgers.Burger do
  @moduledoc """
  A burger with some attributes that can be reviewed.
  """

  use Ecto.Schema
  alias Irateburgers.{Burger, Review}

  @derive {Poison.Encoder, except: [:__meta__]}

  @primary_key false
  embedded_schema do
    field :id, :binary_id
    field :version, :integer
    field :name, :string
    field :price, :string
    field :description, :string
    field :images, {:array, :string}
    embeds_many :reviews, Irateburgers.Review
  end
  @type t :: %__MODULE__{}

  @doc """
  Find the review for the given burger submitted with the given username.
  Return `nil` if no review found.
  """
  @spec find_review_by_user(Burger.t, binary) :: Review.t | nil
  def find_review_by_user(
    burger = %Burger{},
    username)
  when
    is_binary(username)
  do
    Enum.find(burger.reviews, &match?(%{username: ^username}, &1))
  end
end
