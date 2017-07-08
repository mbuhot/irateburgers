defmodule Irateburgers.Application do
  @moduledoc """
  Application entry point for `Irateburgers`
  """
  use Application
  import Supervisor.Spec

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
