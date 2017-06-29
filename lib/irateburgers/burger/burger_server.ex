defmodule Irateburgers.BurgerServer do
  use GenServer
  alias Irateburgers.{Burger, CreateBurger, Web.ErrorHelpers, ReviewBurger, Repo}
  alias Ecto.Changeset

  def start_link(burger = %Burger{}) do
    GenServer.start_link(__MODULE__, burger, name: via_tuple(burger.id))
  end

  defp via_tuple(burger_id), do: {:via, Registry, {Irateburgers.Registry, burger_id}}

  defp find_burger_pid(burger_id) do
    case Registry.lookup(Irateburgers.Registry, burger_id) do
      [{:ok, pid}] -> pid
      [] ->
        case start_link(%Burger{id: burger_id, version: 0}) do
          {:ok, pid} -> pid
          {:error, :already_registered, pid} -> pid
        end
    end
  end

  def create(command = %CreateBurger{id: id}) do
    GenServer.call(find_burger_pid(id), command)
  end

  def review_burger(command = %ReviewBurger{burger_id: burger_id}) do
    GenServer.call(find_burger_pid(burger_id), command)
  end

  def handle_call(command = %CreateBurger{}, _from, burger = %Burger{}) do
    execute_command(command, burger)
  end

  def handle_call(command = %ReviewBurger{}, _from, burger = %Burger{}) do
    execute_command(command, burger)
  end

  defp execute_command(command, burger = %Burger{}) do
    result = Repo.transaction fn ->
      # establish advisory lock...
      with {:ok, [event]} <- command.__struct__.execute(command, burger),
           event_log <- event.__struct__.to_eventlog(event),
           {:ok, _} <- insert_event(event_log) do
        Burger.apply_events(burger, [event])
      else
        {:error, changeset = %Changeset{}} ->
          Repo.rollback(ErrorHelpers.errors_on(changeset))

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end
    case result do
      {:ok, new_burger} -> {:reply, {:ok, new_burger}, new_burger}
      {:error, reason} -> {:reply, {:error, reason}, burger}
    end
  end

  defp insert_event(event) do
    event
    |> Changeset.change()
    |> Changeset.unique_constraint(:sequence, name: :events_aggregate_sequence_index)
    |> Repo.insert()
  end
end
