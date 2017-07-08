defmodule Irateburgers.Event do
  @moduledoc """
  Ecto schema for storing events in the database.
  Provides convenience functions for converting to/from custom struct types and applying an event to an aggregate.
  """

  use Ecto.Schema
  alias Irateburgers.{Event, EventProtocol}

  schema "events" do
    field :aggregate, :binary_id
    field :sequence, :integer
    field :type, :string
    field :payload, :map
  end

  def to_struct(event = %Event{type: type}) do
    type
    |> String.to_existing_atom()
    |> apply(:from_event_log, [event])
  end

  def from_struct(struct) do
    EventProtocol.to_event_log(struct)
  end

  def apply(event, aggregate) do
    EventProtocol.apply(event, aggregate)
  end
end
