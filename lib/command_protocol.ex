defprotocol Irateburgers.CommandProtocol do
  @doc "Execute the current command against an aggregate, returning {:ok, events} on success of {:error, reason} otherwise"
  def execute(command, aggregate)
end
