defmodule Irateburgers.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Registry, [:unique, Irateburgers.Registry]),
      supervisor(Irateburgers.Repo, []),
      supervisor(Irateburgers.Web.Endpoint, []),
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Irateburgers.Supervisor)
  end
end
