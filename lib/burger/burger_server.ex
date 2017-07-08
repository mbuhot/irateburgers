defmodule Irateburgers.BurgerServer do
  @moduledoc """
  Maintains the state of a Burger aggregate, providing an API to execute commands, or get the current state.

  Most of the details are delegated to the `Aggregate` and `Command` modules to load the current state, execute commands,
  and commit new events to the event log.
  """
  alias Irateburgers.{Aggregate, Burger, CreateBurger, ReviewBurger}

  @doc """
  Create a new Burger.

  Returns {:ok, %Burger{}} on success, or {:error, reason} on failure.
  """
  def create(command = %CreateBurger{id: id}) when is_binary(id) do
    dispatch_command(id, command)
  end

  @doc """
  Review a burger.

  Returns {:ok, burger} on success, {:error, reason} on failure.
  Use the `Burger` module to locate the newly created review by username.
  """
  def review_burger(command = %ReviewBurger{burger_id: burger_id})
  when is_binary(burger_id) do
    dispatch_command(burger_id, command)
  end

  @doc """
  Get the current state of a BurgerServer by burger ID.
  """
  def get_burger(id) when is_binary(id) do
    id
    |> Aggregate.find_or_start(%Burger{id: id, version: 0})
    |> Agent.get(& &1)
  end

  # Ensure agent started and dispatch command to process
  defp dispatch_command(id, command = %{}) when is_binary(id) do
    id
    |> Aggregate.find_or_start(%Burger{id: id, version: 0})
    |> Aggregate.dispatch_command(command)
  end
end
