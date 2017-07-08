defmodule Irateburgers.Repo do
  use Ecto.Repo, otp_app: :irateburgers

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, opts) do
    {:ok, Keyword.put(opts, :url, System.get_env("DATABASE_URL"))}
  end

  def stream_events(types: types, position: position) do
    require Ecto.Query, as: Query
    alias Irateburgers.Event

    query =
      Query.from(e in Event,
      where: e.type in ^(Enum.map(types, &to_string/1)),
      where: e.id >= ^position)

    query |> stream() |> Stream.map(&Event.to_struct/1)
  end
end
