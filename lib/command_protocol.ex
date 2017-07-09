defprotocol Irateburgers.CommandProtocol do
  alias Irateburgers.{CommandProtocol, EventProtocol}
  @dialyzer {:nowarn_function, __protocol__: 1}

  @doc """
  Execute the current command against an aggregate,
  returning {:ok, events} on success of {:error, reason} otherwise
  """
  @spec execute(CommandProtocol.t, map) :: {:ok, [EventProtocol.t]} | {:error, term}
  def execute(command, aggregate)
end
