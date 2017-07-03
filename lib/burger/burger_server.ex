defmodule Irateburgers.BurgerServer do
  @moduledoc """
  Maintains the state of a Burger aggregate, providing an API to execute commands, or get the current state.

  Most of the details are delegated to the `Aggregate` and `Command` modules to load the current state, execute commands,
  and commit new events to the event log.
  """
  alias Irateburgers.{Aggregate, Burger, CreateBurger, Command, ReviewBurger}

  @doc """
  Create a new Burger.

  Returns {:ok, %Burger{}} on success, or {:error, reason} on failure.
  """
  def create(command = %CreateBurger{id: id}) do
    dispatch_command(id, command)
  end

  @doc """
  Review a burger.

  Returns {:ok, burger} on success, {:error, reason} on failure.
  Use the `Burger` module to locate the newly created review by username.
  """
  def review_burger(command = %ReviewBurger{burger_id: burger_id}) do
    dispatch_command(burger_id, command)
  end

  @doc """
  Get the current state of a BurgerServer by burger ID.
  """
  def get_burger(id) do
    pid = Aggregate.find_or_start(id, %Burger{id: id, version: 0})
    Agent.get(pid, & &1)
  end

  defp dispatch_command(id, command) do
    id
    |> Aggregate.find_or_start(%Burger{id: id, version: 0})
    |> Agent.get_and_update(fn burger = %Burger{} ->
      case Command.execute(command, burger) do
        {:ok, new_burger} ->
          {{:ok, new_burger}, new_burger}
        {:error, reason} ->
          {{:error, reason}, burger}
      end
    end)
  end
end
