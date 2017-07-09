defmodule Irateburgers.Aggregate do
  @moduledoc """
  Defines common helpers for working with Aggregates.

  Aggregates are represented as `Agent` processes holding some state.
  The state must at least have `id` `:binary_id` and `version` `:integer` keys.
  """

  alias Irateburgers.{Command, CommandProtocol, Event, Repo}
  require Ecto.Query, as: Query

  @type aggregate_id :: binary
  @type aggregate :: %{
    :id => aggregate_id,
    :version => integer,
    atom => term
  }
  @type event :: %{
    :version => integer,
    atom => term
  }

  @doc """
  Finds Aggregate process by id,
  or starts one using the given initial state and module.
  """
  @spec find_or_start(aggregate_id, aggregate) :: pid
  def find_or_start(id, initial = %{id: id, version: 0}) do
    case Registry.lookup(Irateburgers.AggregateRegistry, id) do
      [{pid, _}] -> pid
      [] ->
        case start_agent(id, initial) do
          {:ok, pid} -> pid
          {:error, {:already_started, pid}} -> pid
        end
    end
  end

  # Start an aggregate agent, registering it in AggregateRegistry under key: id
  @spec start_agent(aggregate_id, aggregate) :: {:ok, pid} | {:error, {:already_started, pid}}
  defp start_agent(id, initial_state) do
    Agent.start(fn ->
        {_new, _old} = Registry.update_value(
          Irateburgers.AggregateRegistry,
          id,
          fn _ -> &ensure_event_applied/2 end)

        init(initial_state)
      end,
      name: {:via, Registry, {Irateburgers.AggregateRegistry, id}})
  end

  #Initialize an aggregate from events in the Repo
  @spec init(aggregate) :: aggregate
  defp init(aggregate = %{id: id, version: version}) do
    db_events = Repo.all(
      Query.from e in Event,
      where: e.aggregate == ^id,
      where: e.sequence > ^version,
      order_by: {:asc, e.sequence})

    events = Enum.map(db_events, &Event.to_struct/1)
    apply_events(aggregate, events)
  end

  @doc """
  Given an aggregate and an event, ensures that the event is applied to the aggregate by one of:
   - Applying the event to the aggregate, if the event version is 1 greater than the aggregate version
   - Loading all new events for the aggregate, if the event version is more than 1 greater than the aggregate version
   - Otherwise return the aggregate as-is if the event version is not greater than the aggregate version
  """
  @spec ensure_event_applied(aggregate, event) :: aggregate
  def ensure_event_applied(
    aggregate = %{version: version},
    event = %{version: event_version})
  do
    cond do
      event_version == version + 1 -> Event.apply(event, aggregate)
      event_version > version + 1 -> init(aggregate)
      event_version <= version -> aggregate
    end
  end

  @spec apply_events(aggregate, list(event)) :: aggregate
  defp apply_events(aggregate, events) when is_list(events) do
    Enum.reduce(events, aggregate, &Event.apply/2)
  end

  @doc """
  Dispatch a command to an Agent PID.

  If the command is successful, updates the agent state and returns {:ok, state}
  If the command fails, returns {:error, reason} leaving the agent state unchanged
  """
  @spec dispatch_command(pid, CommandProtocol.t) :: {:ok, aggregate} | {:error, term}
  def dispatch_command(pid, command = %{}) when is_pid(pid) do
    Agent.get_and_update pid, fn state ->
      with {:ok, events} <- Command.execute(command, state) do
        new_state = apply_events(state, events)
        {{:ok, new_state}, new_state}
      else
        {:error, reason} ->
          {{:error, reason}, state}
      end
    end
  end
end
