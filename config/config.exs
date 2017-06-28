# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :irateburgers,
  ecto_repos: [Irateburgers.Repo]

# Configures the endpoint
config :irateburgers, Irateburgers.Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "jqwYFP5wjKUljM5Dbvl4nNwv+BFkeLGjzy57Ihq8nB1gNGZsacrQUFTGA4Nhbtma",
  render_errors: [view: Irateburgers.Web.ErrorView, accepts: ~w(json)],
  pubsub: [name: Irateburgers.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
