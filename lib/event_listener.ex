defmodule Irateburgers.EventListener do
  @moduledoc """
  GenServer to listen for events from postrges notify on the "events" channel.

  To register for events, use the `Irateburgers.EventListenerRegistry`.
  """
  use GenServer
  alias Irateburgers.{Event, EventListenerRegistry, AggregateRegistry, Repo}
  alias Postgrex.Notifications, as: PgNotifications

  defmodule State do
    defstruct [:notifications_pid, :notifications_ref, :notifications_channel]
    @type t :: %__MODULE__{
      notifications_pid: pid,
      notifications_ref: reference,
      notifications_channel: binary
    }
  end

  @doc """
  Starts an EventListener GenServer process
  """
  @spec start_link :: {:ok, pid} | {:error, term}
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc """
  Start a linked `Postgres.Notifications` listener

  Listens on the "events" channel
  """
  @spec init(term) :: {:ok, State.t}
  def init(_args) do
    channel = "events"
    pg_config = Application.get_env(:irateburgers, Repo)
    {:ok, pid} = PgNotifications.start_link(pg_config)
    {:ok, ref} = PgNotifications.listen(pid, channel)
    {:ok, %State{
      notifications_pid: pid,
      notifications_ref: ref,
      notifications_channel: channel
    }}
  end

  @doc """
  Handle messages received from Postgres.Notifications

  Events are sent to aggregates and event listeners
  """
  @spec handle_info(term, State.t) :: {:noreply, State.t}
  def handle_info({:notification, _, _, _, payload}, state = %{}) do
    %{
      "id" => id,
      "aggregate" => aggregate_id,
      "type" => type
    } = Poison.decode!(payload)

    for_event =
      Registry.lookup(EventListenerRegistry, String.to_existing_atom(type))
    for_aggregate = Registry.lookup(AggregateRegistry, aggregate_id)
    send_event_to_subscribers(id, for_aggregate ++ for_event)
    {:noreply, state}
  end
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  @spec send_event_to_subscribers(integer, [pid]) :: :ok
  def send_event_to_subscribers(_event_id, []), do: :ok
  def send_event_to_subscribers(event_id, pids)
  when
    is_integer(event_id) and
    is_list(pids)
  do
    event = Event |> Repo.get(event_id) |> Event.to_struct()
    Enum.each(pids, fn {pid, update_fn} ->
      Agent.cast(pid, fn state ->
        update_fn.(state, event)
      end)
    end)
  end
end
