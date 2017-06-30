defmodule Irateburgers.Application do
  use Application
  import Supervisor.Spec

  def start(_type, _args) do

    children = [
      supervisor(Registry, [:unique, Irateburgers.Registry]),
      supervisor(Irateburgers.Repo, []),
      supervisor(Irateburgers.Web.Endpoint, []),
      worker(Irateburgers.EventListener, [])
    ]
    Supervisor.start_link(children, strategy: :one_for_one, name: Irateburgers.Supervisor)
  end
end
