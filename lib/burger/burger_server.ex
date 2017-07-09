defmodule Irateburgers.BurgerServer do
  @moduledoc """
  Maintains the state of a Burger aggregate, providing an API to execute commands, or get the current state.

  Most of the details are delegated to the `Aggregate` and `Command` modules to load the current state, execute commands,
  and commit new events to the event log.
  """
  alias Irateburgers.{Aggregate, Burger, CreateBurger, CommandProtocol, ReviewBurger}

  @doc """
  Create a new Burger.

  Returns {:ok, %Burger{}} on success, or {:error, reason} on failure.
  """
  @spec create(CreateBurger.t) :: {:ok, Burger.t} | {:error, term}
  def create(command = %CreateBurger{id: id}) when is_binary(id) do
    dispatch_command(id, command)
  end

  @doc """
  Review a burger.

  Returns {:ok, burger} on success, {:error, reason} on failure.
  Use the `Burger` module to locate the newly created review by username.
  """
  @spec review_burger(ReviewBurger.t) :: {:ok, Burger.t} | {:error, term}
  def review_burger(command = %ReviewBurger{burger_id: burger_id})
  when is_binary(burger_id) do
    dispatch_command(burger_id, command)
  end

  @doc """
  Get the current state of a BurgerServer by burger ID.
  """
  @spec get_burger(binary) :: Burger.t
  def get_burger(id) when is_binary(id) do
    id
    |> Aggregate.find_or_start(%Burger{id: id, version: 0})
    |> Agent.get(& &1)
  end

  # Ensure agent started and dispatch command to process
  @spec dispatch_command(binary, CommandProtocol.t) :: {:ok, Burger.t} | {:error, term}
  defp dispatch_command(id, command = %{}) when is_binary(id) do
    id
    |> Aggregate.find_or_start(%Burger{id: id, version: 0})
    |> Aggregate.dispatch_command(command)
  end
end
