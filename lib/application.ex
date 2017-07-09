defmodule Irateburgers.Application do
  @moduledoc """
  Application entry point for `Irateburgers`
  """
  use Application
  import Supervisor.Spec

  @spec start(atom, Keyword.t) :: {:ok, pid} | {:error, term}
  def start(_type, _args) do
    children = [
      supervisor(Irateburgers.Web.Endpoint, []),
      supervisor(Irateburgers.Repo, []),
      aggregate_registry_supervisor(),
      event_listener_registry(),
      worker(Irateburgers.EventListener, []),
      worker(Irateburgers.TopBurgers.Server, [])
    ]
    Supervisor.start_link(
      children,
      strategy: :one_for_one,
      name: Irateburgers.Supervisor)
  end

  @spec aggregate_registry_supervisor :: Supervisor.Spec.spec
  defp aggregate_registry_supervisor do
    supervisor(
      Registry,
      [
        :unique,
        Irateburgers.AggregateRegistry,
        [partitions: System.schedulers_online]
      ],
      id: Irateburgers.AggregateRegistry)
  end

  @spec event_listener_registry :: Supervisor.Spec.spec
  defp event_listener_registry do
    supervisor(
      Registry,
      [
        :duplicate,
        Irateburgers.EventListenerRegistry,
        [partitions: System.schedulers_online]
      ],
      id: Irateburgers.EventListenerRegistry)
  end
end
