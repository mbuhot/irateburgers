defmodule Irateburgers.Aggregate do
  alias Irateburgers.{Event, Repo}
  require Ecto.Query, as: Query

  @doc """
  Initialize an aggregate from events in the Repo
  """
  def init(aggregate = %{id: id, version: version}) do
    db_events = Repo.all(
      Query.from e in Event,
      where: e.aggregate == ^id,
      where: e.sequence > ^version,
      order_by: {:asc, e.sequence})

    events = Enum.map(db_events, &Event.to_struct/1)
    apply_events(aggregate, events)
  end

  @doc """
  Build a via-tuple that can be used to message an aggregate process using the Registry
  """
  def via_tuple(id), do: {:via, Registry, {Irateburgers.AggregateRegistry, id}}

  @doc """
  Finds Aggregate process by id, or starts one using the given initial state and module.
  """
  def find_or_start(id, initial = %{id: id, version: 0}) do
    case Registry.lookup(Irateburgers.AggregateRegistry, id) do
      [{pid, _}] when is_pid(pid) -> pid
      [] ->
        case start_agent(id, initial) do
          {:ok, pid} -> pid
          {:error, :already_registered, pid} -> pid
        end
    end
  end

  defp start_agent(id, initial_state) do
    Agent.start_link(fn ->
      Registry.register(Irateburgers.AggregateRegistry, id, &ensure_event_applied/2)
      init(initial_state)
    end)
  end

  @doc """
  Given an aggregate and an event, ensures that the event is applied to the aggregate by one of:
   - Applying the event to the aggregate, if the event version is 1 greater than the aggregate version
   - Loading all new events for the aggregate, if the event version is more than 1 greater than the aggregate version
   - Otherwise return the aggregate as-is if the event version is not greater than the aggregate version
  """
  def ensure_event_applied(aggregate = %{version: version}, event = %{version: event_version}) do
    cond do
      event_version == version + 1 -> Event.apply(event, aggregate)
      event_version > version + 1 -> init(aggregate)
      event_version <= version -> aggregate
    end
  end

  @doc """
  Applies a list of events in order to an aggregate
  """
  def apply_events(aggregate, events) when is_list(events) do
    Enum.reduce(events, aggregate, &Event.apply/2)
  end
end
