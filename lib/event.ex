defmodule Irateburgers.Event do
  use Ecto.Schema
  alias Irateburgers.Event

  schema "events" do
    field :aggregate, :binary_id
    field :sequence, :integer
    field :type, :string
    field :payload, :map
  end

  def to_struct(event = %Event{type: type}) do
    String.to_existing_atom(type).from_event_log(event)
  end

  def from_struct(struct) do
    struct.__struct__.to_eventlog(struct)
  end

  def apply(event, aggregate) do
    event.__struct__.apply(event, aggregate)
  end
end
