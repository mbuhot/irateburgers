defmodule Irateburgers.TopBurgers do
  @moduledoc """
  Read-model for querying the top rated burgers of all time.
  """

  defmodule Record do
    @moduledoc """
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
    @type t :: %__MODULE__{}

    @spec new(Keyword.t | map) :: {:ok, Record.t} | {:error, term}
    def new(params) do
      case changeset(%__MODULE__{}, Map.new(params)) do
        cs = %{valid?: true} -> {:ok, Changeset.apply_changes(cs)}
        cs -> {:error, ErrorHelpers.errors_on(cs)}
      end
    end

    @spec changeset(Record.t, map) :: Changeset.t
    def changeset(struct, params) do
      struct
      |> Changeset.cast(params, __schema__(:fields))
      |> Changeset.validate_required(__schema__(:fields))
    end
  end

  defmodule Model do
    @moduledoc """
    This structure defines the model of the all-time top burgers.

    It maintains a map of Records by burger-id, which will be incrementally
    updated as Reviews are submitted, and a list of records sorted by average
    review.

    The position in the global event log is maintained to ensure old/duplicated
    events are not applied.
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
    @type t :: %__MODULE__{}

    # Ignore events that were already procesed when the model was initialized
    @spec apply_event(Model.t, map) :: Model.t
    def apply_event(
      model = %Model{last_event_id: n},
      _event = %{id: m})
    when
      is_integer(m) and
      is_integer(n) and
      m <= n
    do
      model
    end

    # Add a new new burger record to the model, initially has no reviews
    def apply_event(
      model = %Model{},
      %BurgerCreated{burger_id: id, name: name, version: version})
    do
      {:ok, record} = Record.new(
        burger_id: id,
        name: name,
        version: version,
        average_rating: 0,
        num_reviews: 0)

      %{model | by_id: Map.put(model.by_id, id, record), by_rating: nil}
    end

    # Update the average rating for a burger after being reviewed
    def apply_event(
      model = %Model{},
      event = %BurgerReviewed{burger_id: burger_id})
    do
      new_burger =
        model
        |> find_burger(burger_id)
        |> update_average_rating(event.rating)

      new_by_id = Map.put(model.by_id, burger_id, new_burger)
      %{model | by_id: new_by_id, by_rating: nil}
    end

    @doc """
    Gets a burger record by ID from the model
    """
    @spec find_burger(Model.t, binary) :: Record.t | nil
    def find_burger(model = %Model{}, burger_id) when is_binary(burger_id) do
      model.by_id[burger_id]
    end

    # Update the given burger record to include a new review with given rating
    @spec update_average_rating(Record.t, integer) :: Record.t
    defp update_average_rating(
      burger = %Record{average_rating: avg, num_reviews: n},
      rating)
    when is_integer(rating) do
      %{burger |
        num_reviews: n + 1,
        average_rating: incremental_average(avg, n, rating)
      }
    end

    @spec incremental_average(number, integer, integer) :: number
    defp incremental_average(avg, count, value) do
      avg * (count / (count + 1)) + (value / (count + 1))
    end

    @doc """
    Sorts the burger records by rating if necessary and takes the top `count`
    returns {records, new_model} so the sorting can be cached
    """
    @spec top_burgers(Model.t, integer) :: {[Record.t], Model.t}
    def top_burgers(
      model = %Model{by_rating: nil},
      count)
    when is_integer(count) do
      new_model = sort_by_rating(model)
      top_burgers(new_model, count)
    end
    def top_burgers(model = %Model{by_rating: records}, count)
    when
      is_list(records) and
      is_integer(count)
    do
      {Enum.take(records, count), model}
    end

    # Sorts the burger records by average_rating descending,
    # updates `model.by_rating` with the result
    @spec sort_by_rating(Model.t) :: Model.t
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

    On initialization, it reads all relevant past events from the event log.
    """

    alias Irateburgers.{
      BurgerCreated,
      BurgerReviewed,
      EventListenerRegistry,
      Repo
    }
    alias Irateburgers.TopBurgers.Model

    @spec start_link() :: {:ok, pid} | {:error, term}
    def start_link do
      Agent.start_link(&init/0, name: __MODULE__)
    end

    # Register this processs in the `EventListenerRegistry` for new events,
    # and stream in the history of past events.
    @spec init() :: Model.t
    def init do
      Registry.register(
        EventListenerRegistry, BurgerCreated, &Model.apply_event/2)

      Registry.register(
        EventListenerRegistry, BurgerReviewed, &Model.apply_event/2)

      {:ok, model} = Repo.transaction(fn ->
        events = Repo.stream_events(
          types: [BurgerCreated, BurgerReviewed], position: 0)

        Enum.reduce(events, %Model{}, fn x, acc ->
          Model.apply_event(acc, x)
        end)
      end)
      model
    end

    @doc """
    Get the top `count` burgers by average rating
    """
    @spec top_burgers(integer) :: [Record.t]
    def top_burgers(count) when is_integer(count) do
      Agent.get_and_update(__MODULE__, &Model.top_burgers(&1, count))
    end
  end
end
