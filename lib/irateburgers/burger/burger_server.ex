defmodule Irateburgers.BurgerServer do
  use GenServer
  alias Irateburgers.{Burger, CreateBurger, Repo}

  def start_link(burger = %Burger{}) do
    GenServer.start_link(__MODULE__, burger, name: via_tuple(burger.id))
  end

  defp via_tuple(burger_id), do: {:via, Registry, {Irateburgers.Registry, burger_id}}

  def create(command = %CreateBurger{id: id}) do
    with [] <- Registry.lookup(Irateburgers.Registry, id),
         {:ok, pid} <- start_link(%Burger{id: id, version: 0})
    do
      GenServer.call(pid, command)
    else
      {:error, {:already_registered, _pid}} -> {:error, :already_exists}
    end
  end

  def handle_call(command = %CreateBurger{}, _from, burger = %Burger{}) do
    result = Repo.transaction fn ->
      # establish advisory lock...
      with {:ok, [event]} <- CreateBurger.execute(command, burger),
           event_log <- event.__struct__.to_eventlog(event),
           {:ok, _} <- Repo.insert(event_log) do
        Burger.apply_events(burger, [event])
      else
        {:error, reason} ->
          Repo.rollback(reason)
      end
    end
    case result do
      {:ok, new_burger} -> {:reply, {:ok, new_burger}, new_burger}
      {:error, reason} -> {:reply, {:error, reason}, burger}
    end
  end
end
