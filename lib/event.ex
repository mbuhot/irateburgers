defmodule Irateburgers.Event do
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
