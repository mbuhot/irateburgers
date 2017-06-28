defmodule Irateburgers.Event do
  use Ecto.Schema

  schema "events" do
    field :aggregate, :binary_id
    field :sequence, :integer
    field :type, :string
    field :payload, :map
  end

end
