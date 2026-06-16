# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :maraga_info,
  ecto_repos: [MaragaInfo.Repo],
  generators: [timestamp_type: :utc_datetime]

# The address campaign emails are sent from. Override in runtime.exs for prod.
config :maraga_info, :mail_from, {"David Maraga Campaign", "no-reply@davidmaraga.info"}

# Oban powers reliable, retryable bulk email delivery.
config :maraga_info, Oban,
  repo: MaragaInfo.Repo,
  engine: Oban.Engines.Basic,
  queues: [mailers: 10, default: 10],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Plugins.Lifeline, rescue_after: :timer.minutes(30)}
  ]

# Configures the endpoint
config :maraga_info, MaragaInfoWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: MaragaInfoWeb.ErrorHTML, json: MaragaInfoWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: MaragaInfo.PubSub,
  live_view: [signing_salt: "yaOz/tLM"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :maraga_info, MaragaInfo.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  maraga_info: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  maraga_info: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :mime, :types, %{
  "video/x-m4v" => ["m4v"]
}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
