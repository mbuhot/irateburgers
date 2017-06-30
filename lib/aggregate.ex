defmodule Irateburgers.Aggregate do
  alias Irateburgers.{Event, Repo}
  require Ecto.Query, as: Query

  @doc """
  Initialize an aggregate from events in the Repo
  """
  def init(aggregate = %{id: id, version: version}) do
    events = Repo.all(
      Query.from e in Event,
      where: e.aggregate == ^id,
      where: e.sequence > ^version,
      order_by: {:asc, e.sequence})

    events
    |> Enum.map(fn e -> String.to_existing_atom(e.type).from_event_log(e) end)
    |> Enum.reduce(aggregate, fn e, acc -> e.__struct__.apply(e, acc) end)
  end

  @doc """
  Build a via-tuple that can be used to message an aggregate GenServer using the Registry
  """
  def via_tuple(id), do: {:via, Registry, {Irateburgers.Registry, id}}

  @doc """
  Finds Aggregate GenServer by id, or starts one using the given initial state and module.
  """
  def find_or_start(id, initial = %{id: id, version: 0}, server_module) do
    case Registry.lookup(Irateburgers.Registry, id) do
      [{pid, _}] when is_pid(pid) -> pid
      [] ->
        case GenServer.start_link(server_module, initial, name: via_tuple(id)) do
          {:ok, pid} -> pid
          {:error, :already_registered, pid} -> pid
        end
    end
  end

  @doc """
  Given an aggregate and an event, ensures that the event is applied to the aggregate by one of:
   - Applying the event to the aggregate, if the event version is 1 greater than the aggregate version
   - Loading all new events for the aggregate, if the event version is more than 1 greater than the aggregate version
   - Otherwise return the aggregate as-is if the event version is not greater than the aggregate version
  """
  def ensure_event_applied(aggregate = %{version: version}, event = %{version: event_version}) do
    cond do
      event_version == version + 1 -> event.__struct__.apply(aggregate)
      event_version > version + 1 -> init(aggregate)
      event_version <= version -> aggregate
    end
  end

  @doc """
  Applies a list of events in order to an aggregate
  """
  def apply_events(aggregate, events) when is_list(events) do
    Enum.reduce(events, aggregate, fn event, acc ->
      event.__struct__.apply(event, acc)
    end)
  end
end