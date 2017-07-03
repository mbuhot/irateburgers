defmodule Irateburgers.CreateBurger do
  use Ecto.Schema
  alias Ecto.Changeset
  alias Irateburgers.{Burger, BurgerCreated, CreateBurger, CommandProtocol, ErrorHelpers}

  @primary_key false
  embedded_schema do
    field :id, :binary_id
    field :name, :string
    field :price, :string
    field :description, :string
    field :images, {:array, :string}
  end

  def new(params) do
    case changeset(%CreateBurger{}, Map.new(params)) do
      cs = %{valid?: true} -> {:ok, Changeset.apply_changes(cs)}
      cs -> {:error, ErrorHelpers.errors_on(cs)}
    end
  end

  def changeset(struct, params) do
    struct
    |> Changeset.cast(params, [:name, :price, :description, :images])
    |> Changeset.put_change(:id, Ecto.UUID.generate())
    |> Changeset.validate_required([:id, :name, :price, :description])
  end

  defimpl CommandProtocol do
    def execute(command = %CreateBurger{id: id}, burger = %Burger{id: id, version: 0}) do
      event = %BurgerCreated{
        burger_id: id,
        version: burger.version + 1,
        name: command.name,
        price: command.price,
        description: command.description,
        images: command.images
      }
      {:ok, [event]}
    end
    def execute(%CreateBurger{id: id}, %Burger{id: id, version: n}) when (n > 0) do
      {:error, :burger_already_exists}
    end
  end
end
