defmodule Irateburgers.EventListener do
  use GenServer
  alias Irateburgers.{Event, Repo}

  @doc """
  Starts an EventListener GenServer process
  """
  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc """
  Start a linked `Postgres.Notifications` listener, listening on the "events" channel
  """
  def init(_args) do
    channel = "events"
    pg_config = Application.get_env(:irateburgers, Irateburgers.Repo)
    {:ok, pid} = Postgrex.Notifications.start_link(pg_config)
    {:ok, ref} = Postgrex.Notifications.listen(pid, channel)
    {:ok, %{notifications_pid: pid, notifications_ref: ref, notifications_channel: channel}}
  end

  @doc """
  Handle messages received from Postgres.Notifications

  Events are sent to aggregates and event listeners
  """
  def handle_info({:notification, _pid, _ref, _channel, payload}, state = %{}) do
    %{"id" => id, "aggregate" => aggregate_id, "type" => type} = Poison.decode!(payload)

    for_event = Registry.lookup(Irateburgers.EventListenerRegistry, String.to_existing_atom(type))
    for_aggregate = Registry.lookup(Irateburgers.AggregateRegistry, aggregate_id)
    send_event_to_subscribers(id, for_aggregate ++ for_event)
    {:noreply, state}
  end
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def send_event_to_subscribers(_event_id, []), do: :ok
  def send_event_to_subscribers(event_id, pids) when is_integer(event_id) and is_list(pids) do
    event = Event |> Repo.get(event_id) |> Event.to_struct()
    Enum.each(pids, fn {pid, update_fn} ->
      Agent.cast(pid, fn state ->
        update_fn.(state, event)
      end)
    end)
  end
end
