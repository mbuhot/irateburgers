defmodule Irateburgers.TopBurgers do
  defmodule Record do
    @doc """
    This struct represents a single row in the Top-Burgers table:

    1. "Resolution Breaker", 4.5, 8 Reviews
    2. "Brooklyn Cheeseburger", 4.3, 5 Reviews
    ...
    """

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
      |> Changeset.cast(params, __schema__(:fields))
      |> Changeset.validate_required(__schema__(:fields))
    end
  end

  defmodule Model do
    @doc """
    This structure defines the model of the all-time top burgers.

    It maintains a map of Records by burger-id, which will be incrementally updated as Reviews are submitted,
    and a list of records sorted by average review.

    The position in the global event log is maintained to ensure old/duplicated events are not applied.
    """

    use Ecto.Schema
    alias Irateburgers.{BurgerCreated, BurgerReviewed}
    alias Irateburgers.TopBurgers.{Record, Model}

    @primary_key false
    embedded_schema do
      field :last_event_id, :integer, default: 0
      field :by_id, {:map, Record}, default: %{}
      embeds_many :by_rating, Record
    end

    # Ignore events that were already procesed when the model was initialized
    def apply_event(model = %Model{last_event_id: n},
                   _event = %{id: m}) when is_integer(m) and is_integer(m) and m <= n do
      model
    end

    # Add a new new burger record to the model, initially has no reviews
    def apply_event(model = %Model{}, %BurgerCreated{burger_id: id, name: name, version: version}) do
      {:ok, record} = Record.new(burger_id: id, name: name, version: version, average_rating: 0, num_reviews: 0)
      %{model | by_id: Map.put(model.by_id, id, record), by_rating: nil}
    end

    # Update the average rating for a burger after being reviewed
    def apply_event(model = %Model{}, event = %BurgerReviewed{burger_id: burger_id}) do
      new_burger =
        model
        |> find_burger(burger_id)
        |> update_average_rating(event.rating)

      %{model | by_id: Map.put(model.by_id, burger_id, new_burger), by_rating: nil}
    end

    @doc """
    Gets a burger record by ID from the model
    """
    def find_burger(model = %Model{}, burger_id) when is_binary(burger_id) do
      model.by_id[burger_id]
    end

    # Update the given burger record to include a new review with given rating
    defp update_average_rating(burger = %Record{}, rating) when is_integer(rating) do
      new_total_reviews = burger.num_reviews + 1
      %{burger |
        num_reviews: new_total_reviews,
        average_rating: burger.average_rating * (burger.num_reviews / new_total_reviews) + (rating / new_total_reviews)
      }
    end

    @doc """
    Sorts the burger records by rating if necessary and takes the top `count`
    return {records, new_model} so the sorting can be cached by TopBurgers.Server
    """
    def top_burgers(model = %Model{by_rating: nil}, count) when is_integer(count) do
      new_model = sort_by_rating(model)
      top_burgers(new_model, count)
    end
    def top_burgers(model = %Model{by_rating: records}, count) when is_list(records) and is_integer(count) do
      {Enum.take(records, count), model}
    end

    # Sorts the burger records by average_rating descending, updates `model.by_rating` with the result
    defp sort_by_rating(model = %Model{by_id: burgers = %{}}) do
      sorted =
        burgers
        |> Map.values()
        |> Enum.sort_by(&Map.get(&1, :average_rating), &>=/2)

      %{model | by_rating: sorted}
    end
  end

  defmodule Server do
    @moduledoc """
    This process maintains the state of the TopBurgers, and listens for events.

    On initialization, it reads all relevant past events from the global event log.
    """

    alias Irateburgers.{BurgerCreated, BurgerReviewed, Repo}
    alias Irateburgers.TopBurgers.Model

    def start_link() do
      Agent.start_link(&init/0, name: __MODULE__)
    end

    # Register this processs in the `EventListenerRegistry` for new events, and stream in the history of past events.
    # TODO: a better approach would be:
    #  1. n = Query database for last event id
    #  2. Register for events
    #  3. Query all events from 0 .. n, guarenteeing that there is no overlap between the query and the notifications
    def init() do
      Registry.register(Irateburgers.EventListenerRegistry, BurgerCreated, &Model.apply_event/2)
      Registry.register(Irateburgers.EventListenerRegistry, BurgerReviewed, &Model.apply_event/2)
      {:ok, model} = Repo.transaction(fn ->
        events = Repo.stream_events(types: [BurgerCreated, BurgerReviewed], position: 0)
        Enum.reduce(events, %Model{}, fn x, acc -> Model.apply_event(acc, x) end)
      end)
      model
    end

    @doc """
    Get the top `count` burgers by average rating
    """
    def top_burgers(count) when is_integer(count) do
      Agent.get_and_update(__MODULE__, &Model.top_burgers(&1, count))
    end
  end
end
