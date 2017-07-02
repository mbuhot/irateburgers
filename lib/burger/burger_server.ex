defmodule Irateburgers.BurgerServer do
  use GenServer
  alias Irateburgers.{Aggregate, Burger, CreateBurger, Command, ReviewBurger}

  def init(burger = %Burger{version: 0}) do
    state = Aggregate.init(burger)
    {:ok, state}
  end

  def create(command = %CreateBurger{id: id}) do
    dispatch_call(id, command)
  end

  def review_burger(command = %ReviewBurger{burger_id: burger_id}) do
    dispatch_call(burger_id, command)
  end

  def get_burger(id) do
    dispatch_call(id, :current_state)
  end

  defp dispatch_call(id, command) do
    pid = Aggregate.find_or_start(id, %Burger{id: id, version: 0}, __MODULE__)
    GenServer.call(pid, command)
  end

  def handle_call(:current_state, _from, burger) do
    {:reply, burger, burger}
  end
  def handle_call(command, _from, burger = %Burger{}) do
    case Command.execute(command, burger) do
      {:ok, new_burger} ->
        {:reply, {:ok, new_burger}, new_burger}
      {:error, reason} ->
        {:reply, {:error, reason}, burger}
    end
  end

  def handle_cast({:event, event}, burger = %Burger{}) do
    {:noreply, Aggregate.ensure_event_applied(burger, event)}
  end
end
