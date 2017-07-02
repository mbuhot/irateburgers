defmodule Irateburgers.Application do
  use Application
  import Supervisor.Spec

  def start(_type, _args) do
    children = [
      supervisor(Irateburgers.Web.Endpoint, []),
      supervisor(Irateburgers.Repo, []),
      supervisor(Registry, [:unique, Irateburgers.AggregateRegistry, [partitions: System.schedulers_online]], id: Irateburgers.AggregateRegistry),
      supervisor(Registry, [:duplicate, Irateburgers.EventListenerRegistry, [partitions: System.schedulers_online]], id: Irateburgers.EventListenerRegistry),
      worker(Irateburgers.EventListener, []),
      worker(Irateburgers.TopBurgers.Server, [])
    ]
    Supervisor.start_link(children, strategy: :one_for_one, name: Irateburgers.Supervisor)
  end
end
