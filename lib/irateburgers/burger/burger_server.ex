defmodule Irateburgers.BurgerServer do
  use GenServer
  alias Irateburgers.{Aggregate, Burger, CreateBurger, Command, ReviewBurger}

  def init(burger = %Burger{version: 0}) do
    {:ok, Aggregate.init(burger)}
  end

  defp dispatch_command(id, command) do
    pid = Aggregate.find_or_start(id, %Burger{id: id, version: 0}, __MODULE__)
    GenServer.call(pid, {:command, command})
  end

  def create(command = %CreateBurger{id: id}) do
    dispatch_command(id, command)
  end

  def review_burger(command = %ReviewBurger{burger_id: burger_id}) do
    dispatch_command(burger_id, command)
  end

  def handle_call({:command, command}, _from, burger = %Burger{}) do
    case Command.execute(command, burger) do
      {:ok, new_burger} ->
        {:reply, {:ok, new_burger}, new_burger}
      {:error, reason} ->
        {:reply, {:error, reason}, burger}
    end
  end
end
