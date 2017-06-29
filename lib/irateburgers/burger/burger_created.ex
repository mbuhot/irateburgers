defmodule Irateburgers.BurgerCreated do
  use Ecto.Schema
  alias Ecto.Changeset
  alias Irateburgers.{Burger, BurgerCreated, Event}

  @primary_key false
  embedded_schema do
    field :id, :binary_id
    field :version, :integer
    field :name, :string
    field :price, :string
    field :description, :string
    field :images, {:array, :string}
  end

  def new(params) do
    case changeset(%BurgerCreated{}, Map.new(params)) do
      cs = %{valid?: true} -> {:ok, Ecto.Changeset.apply_changes(cs)}
      cs -> {:error, cs}
    end
  end

  def changeset(struct, params) do
    struct
    |> Changeset.cast(params, [:id, :version, :name, :price, :description, :images])
    |> Changeset.validate_required([:id, :version, :name, :price, :description])
  end

  def apply(event = %BurgerCreated{id: id}, burger = %Burger{id: id}) do
    %{burger |
      version: event.version,
      name: event.name,
      price: event.price,
      description: event.description,
      images: event.images
    }
  end

  def to_eventlog(event = %BurgerCreated{}) do
    %Event{
      aggregate: event.id,
      sequence: event.version,
      type: to_string(__MODULE__),
      payload: %{
        name: event.name,
        price: event.price,
        description: event.description,
        images: event.images
      }
    }
  end

  def from_event_log(event = %Event{}) do
    {:ok, domain_event} =
      BurgerCreated.new(
        Map.merge(
          event.payload,
          %{"id" => event.aggregate, "version" => event.sequence}))

    domain_event
  end
end
