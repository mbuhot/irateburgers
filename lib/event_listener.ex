defmodule Irateburgers.EventListener do
  use GenServer
  alias Irateburgers.{Event, Repo}

  @doc """
  Starts an EventListener GenServer process
  """
  def start_link() do
    GenServer.start_link(__MODULE__, nil)
  end

  @doc """
  Start a linked `Postgres.Notifications` listener, listening on the "events" channel
  """
  def init(_args) do
    channel = "events"
    pg_config = Application.get_env(:irateburgers, Irateburgers.Repo)
    {:ok, pid} = Postgrex.Notifications.start_link(pg_config)
    {:ok, ref} = Postgrex.Notifications.listen(pid, channel)
    {:ok, {pid, ref, channel}}
  end

  @doc """
  Handle messages received from Postgres.Notifications

  If a matching Aggregate GenServer is running, it will be notified of the event, otherwise the event is ignored.
  """
  def handle_info({:notification, pid, ref, channel, payload}, state = {pid, ref, channel}) do
    %{"id" => id, "aggregate" => aggregate_id} = Poison.decode!(payload)
    case Registry.lookup(Irateburgers.Registry, aggregate_id) do
      [{pid, _}] when is_pid(pid) ->
        event = Event |> Repo.get(id) |> Event.to_struct()
        send(pid, {:event, event})
      [] ->
        nil
    end
    {:noreply, state}
  end
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
