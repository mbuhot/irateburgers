defmodule Irateburgers.Aggregate do
  alias Irateburgers.{Event, Repo}
  require Ecto.Query, as: Query

  @doc """
  Initialize an aggregate from events in the Repo
  """
  def init(aggregate = %{id: id, version: 0}) do
    events = Repo.all(
      Query.from e in Event,
      where: e.aggregate == ^id,
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
end
