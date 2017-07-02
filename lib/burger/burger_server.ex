defmodule Irateburgers.BurgerServer do
  @doc """
  Maintains the state of a Burger aggregate, providing an API to execute commands, or get the current state.

  Most of the details are delegated to the `Aggregate` and `Command` modules to load the current state, execute commands,
  and commit new events to the event log.
  """

  use GenServer
  alias Irateburgers.{Aggregate, Burger, CreateBurger, Command, ReviewBurger}

  def init(burger = %Burger{version: 0}) do
    state = Aggregate.init(burger)
    {:ok, state}
  end

  @doc """
  Create a new Burger.

  Returns {:ok, %Burger{}} on success, or {:error, reason} on failure.
  """
  def create(command = %CreateBurger{id: id}) do
    dispatch_call(id, command)
  end

  @doc """
  Review a burger.

  Returns {:ok, burger} on success, {:error, reason} on failure.
  Use the `Burger` module to locate the newly created review by username.
  """
  def review_burger(command = %ReviewBurger{burger_id: burger_id}) do
    dispatch_call(burger_id, command)
  end

  @doc """
  Get the current state of a BurgerServer by burger ID.
  """
  def get_burger(id) do
    dispatch_call(id, :current_state)
  end

  # Ensures an appropritate GenServer is running for the given burger ID, then call it with a command.
  defp dispatch_call(id, command) do
    pid = Aggregate.find_or_start(id, %Burger{id: id, version: 0}, __MODULE__)
    GenServer.call(pid, command)
  end

  # Handle the :current_state call specially, since it doesn't require a transaction
  def handle_call(:current_state, _from, burger) do
    {:reply, burger, burger}
  end

  # Handle a call with a command structure
  def handle_call(command, _from, burger = %Burger{}) do
    case Command.execute(command, burger) do
      {:ok, new_burger} ->
        {:reply, {:ok, new_burger}, new_burger}
      {:error, reason} ->
        {:reply, {:error, reason}, burger}
    end
  end

  # Handle async events cast to this GenServer
  # Events generated by executing a command on this GenServer will already have been applied,
  # but events originating from another node will not yet have been applied.
  def handle_cast({:event, event}, burger = %Burger{}) do
    {:noreply, Aggregate.ensure_event_applied(burger, event)}
  end
end
