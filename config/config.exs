# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :turnStile,
  ecto_repos: [TurnStile.Repo]

# Configures the endpoint
config :turnStile, TurnStileWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: TurnStileWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: TurnStile.PubSub,
  live_view: [signing_salt: "sb/gRhIU"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :turnStile, TurnStile.Mailer,
      adapter: Swoosh.Adapters.Mailgun,
      domain: System.get_env("MAILGUN_DOMAIN"),
      api_key: System.get_env("MAILGUN_API_KEY"),
      debug: true

  # Swoosh API client is needed for adapters other than SMTP.
 config :swoosh,
      api_client: Swoosh.ApiClient.Hackney

config :ex_twilio,
account_sid:    System.get_env("TWILIO_ACCOUNT_SID"),
auth_token:     System.get_env("TWILIO_AUTH_TOKEN"),
workspace_sid:  System.get_env("TWILIO_WORKSPACE_SID")

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.29",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :debug,
  truncate: :infinity

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Non-Secret ENV variables
# HOW-TOApplication.fetch_env!(:turnStile, :hello))
# config :turnStile,
# welcome: "config!",
# hello: "world"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
