defmodule Irateburgers.Command do
  @moduledoc """
  Handles locking and event persistence for command execution.
  """

  alias Irateburgers.{CommandProtocol, ErrorHelpers, Event, Repo}
  alias Ecto.Changeset

  @doc """
  Execute a command against an aggregate, commiting the resulting events to the event log.
  Returns {:ok, events} on success, or {:error, reason} otherwise.
  """
  def execute(command, aggregate = %{id: id}) do
    Repo.transaction fn ->
      Repo.query("SELECT pg_advisory_xact_lock($1)", [:erlang.phash2(id)])
      with {:ok, events} <- CommandProtocol.execute(command, aggregate),
           :ok <- log_events(events) do
        events
      else
        {:error, changeset = %Changeset{}} ->
          Repo.rollback(ErrorHelpers.errors_on(changeset))

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end
  end

  # Converts domain event structs to database events and persists
  defp log_events([]), do: :ok
  defp log_events([event | rest]) do
    db_event = Event.from_struct(event)
    with {:ok, _} <- insert_event(db_event) do
      log_events(rest)
    end
  end

  # Insert a database event struct in the events table,
  # handling optimistic concurrency errors if another process has already
  # committed events to the event log for the same aggregate
  defp insert_event(event = %Event{}) do
    event
    |> Changeset.change()
    |> aggregate_sequence_constraint()
    |> Repo.insert()
  end

  defp aggregate_sequence_constraint(changeset = %Changeset{}) do
    Changeset.unique_constraint(
      changeset,
      :sequence,
      name: :events_aggregate_sequence_index)
  end
end
