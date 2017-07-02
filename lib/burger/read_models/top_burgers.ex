defmodule Irateburgers.TopBurgers do
  defmodule Record do
    use Ecto.Schema
    alias Ecto.Changeset
    alias Irateburgers.ErrorHelpers

    @primary_key false
    embedded_schema do
      field :burger_id, :binary_id
      field :name, :string
      field :version, :integer
      field :average_rating, :float
      field :num_reviews, :integer
    end

    def new(params) do
      case changeset(%__MODULE__{}, Map.new(params)) do
        cs = %{valid?: true} -> {:ok, Changeset.apply_changes(cs)}
        cs -> {:error, ErrorHelpers.errors_on(cs)}
      end
    end

    def changeset(struct, params) do
      struct
      |> Changeset.cast(params, [:burger_id, :name, :average_rating, :num_reviews])
      |> Changeset.validate_required([:burger_id, :name, :average_rating, :num_reviews])
    end
  end

  defmodule Model do
    alias Irateburgers.{BurgerCreated, BurgerReviewed}
    alias Irateburgers.TopBurgers.{Record, Model}

    defstruct last_event_id: 0, by_rating: nil, by_id: %{}

    def apply_event(model = %Model{}, %BurgerCreated{burger_id: id, name: name, version: version}) do
      {:ok, record} = Record.new(burger_id: id, name: name, version: version, average_rating: 0, num_reviews: 0)
      %{model | by_id: Map.put(model.by_id, id, record), by_rating: nil}
    end

    def apply_event(model = %Model{}, event = %BurgerReviewed{}) do
      burger = %Record{} = find_burger(model, event.burger_id)
      update_average_rating(model, burger, event)
    end

    def find_burger(model = %Model{}, burger_id) when is_binary(burger_id) do
      model.by_id[burger_id]
    end

    def update_average_rating(model = %Model{}, burger = %Record{}, event = %BurgerReviewed{}) do
      new_total_reviews = burger.num_reviews + 1
      new_burger = %{burger |
        num_reviews: new_total_reviews,
        average_rating: burger.average_rating * (burger.num_reviews / new_total_reviews) + (event.rating / new_total_reviews)
      }
      %{model | by_id: Map.put(model.by_id, burger.burger_id, new_burger), by_rating: nil}
    end

    def top_burgers(model = %Model{by_rating: nil}, count) when is_integer(count) do
      new_model = sort_by_rating(model)
      top_burgers(new_model, count)
    end
    def top_burgers(model = %Model{by_rating: records}, count) when is_list(records) and is_integer(count) do
      {model, Enum.take(records, count)}
    end

    defp sort_by_rating(model = %Model{by_id: burgers = %{}}) do
      sorted =
        burgers
        |> Map.values()
        |> Enum.sort_by(&Map.get(&1, :average_rating), &>=/2)

      %{model | by_rating: sorted}
    end
  end

  defmodule Server do
    use GenServer
    alias Irateburgers.{BurgerCreated, BurgerReviewed, Repo}
    alias Irateburgers.TopBurgers.Model

    def start_link() do
      GenServer.start_link(__MODULE__, %Model{}, name: __MODULE__)
    end

    def init(model = %Model{}) do
      Registry.register(Irateburgers.EventListenerRegistry, BurgerCreated, nil)
      Registry.register(Irateburgers.EventListenerRegistry, BurgerReviewed, nil)
      {:ok, model} = Repo.transaction(fn ->
        events = Repo.stream_events(types: [BurgerCreated, BurgerReviewed], position: 0)
        Enum.reduce(events, model, fn x, acc -> Model.apply_event(acc, x) end)
      end)

      {:ok, model}
    end

    def top_burgers(count) when is_integer(count) do
      GenServer.call(__MODULE__, {:top_burgers, count})
    end

    def handle_call({:top_burgers, count}, _from, model = %Model{}) when is_integer(count) do
      {new_model, result} = Model.top_burgers(model, count)
      {:reply, result, new_model}
    end

    def handle_cast({:event, event = %{id: id}},
                    state = %Model{last_event_id: last_event_id}) when (last_event_id < id) do
      new_state = Model.apply_event(state, event)
      {:noreply, new_state}
    end
    def handle_cast(_msg, state) do
      {:noreply, state}
    end
  end
end
