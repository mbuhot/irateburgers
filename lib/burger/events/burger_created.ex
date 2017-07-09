defmodule Irateburgers.BurgerCreated do
  @moduledoc """
  Event raised after `CreateBurger` commandn is executed.
  """

  use Ecto.Schema
  alias Ecto.Changeset
  alias Irateburgers.{Burger, BurgerCreated, ErrorHelpers, EventProtocol, Event}

  @primary_key false
  embedded_schema do
    field :id, :integer
    field :burger_id, :binary_id
    field :version, :integer
    field :name, :string
    field :price, :string
    field :description, :string
    field :images, {:array, :string}
  end
  @type t :: %__MODULE__{}

  @spec new(Keyword.t | map) :: {:ok, BurgerCreated.t} | {:error, term}
  def new(params) do
    case changeset(%BurgerCreated{}, Map.new(params)) do
      cs = %{valid?: true} -> {:ok, Changeset.apply_changes(cs)}
      cs -> {:error, ErrorHelpers.errors_on(cs)}
    end
  end

  @spec changeset(BurgerCreated.t, map) :: Changeset.t
  def changeset(struct, params) do
    struct
    |> Changeset.cast(params, __schema__(:fields))
    |> Changeset.validate_required(__schema__(:fields) -- [:id, :images])
  end

  defimpl EventProtocol do
    @spec apply(BurgerCreated.t, Burger.t) :: Burger.t
    def apply(
      event = %BurgerCreated{burger_id: burger_id, version: 1},
      burger = %Burger{id: burger_id, version: 0})
    do
      %{burger |
        version: event.version,
        name: event.name,
        price: event.price,
        description: event.description,
        images: event.images
      }
    end

    @spec to_event_log(BurgerCreated.t) :: Event.t
    def to_event_log(event = %BurgerCreated{}) do
      %Event{
        aggregate: event.burger_id,
        sequence: event.version,
        type: to_string(Irateburgers.BurgerCreated),
        payload: %{
          name: event.name,
          price: event.price,
          description: event.description,
          images: event.images
        }
      }
    end
  end

  @spec from_event_log(Event.t) :: BurgerCreated.t
  def from_event_log(event = %Event{}) do
    {:ok, domain_event} =
      BurgerCreated.new(
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
