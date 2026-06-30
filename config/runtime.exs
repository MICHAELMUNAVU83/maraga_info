import Config

root_dir = Path.expand("..", __DIR__)

strip_wrapping_quotes = fn value ->
  trimmed = String.trim(value)

  cond do
    String.length(trimmed) >= 2 and String.starts_with?(trimmed, "\"") and
        String.ends_with?(trimmed, "\"") ->
      trimmed
      |> String.trim_leading("\"")
      |> String.trim_trailing("\"")

    String.length(trimmed) >= 2 and String.starts_with?(trimmed, "'") and
        String.ends_with?(trimmed, "'") ->
      trimmed
      |> String.trim_leading("'")
      |> String.trim_trailing("'")

    true ->
      trimmed
  end
end

load_dotenv_file = fn path ->
  if File.exists?(path) do
    path
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Enum.each(fn
      "" ->
        :ok

      "#" <> _comment ->
        :ok

      line ->
        case Regex.run(~r/^(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/, line) do
          [_, key, raw_value] ->
            if System.get_env(key) in [nil, ""] do
              System.put_env(key, strip_wrapping_quotes.(raw_value))
            end

          _ ->
            :ok
        end
    end)
  end
end

[Path.join(root_dir, ".env"), Path.join(root_dir, ".env.#{config_env()}")]
|> Enum.each(load_dotenv_file)

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/maraga_info start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :maraga_info, MaragaInfoWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :maraga_info, MaragaInfo.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "davidmaraga.info"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :maraga_info, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :maraga_info, MaragaInfoWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :maraga_info, MaragaInfoWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :maraga_info, MaragaInfoWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :maraga_info, MaragaInfo.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.

end

# The "From" address and delivery adapter are configured for all environments
# so that test sends work in dev as well as production.

# The "From" address used by the bulk email composer.
if from = System.get_env("MAIL_FROM") do
  config :maraga_info,
         :mail_from,
         {System.get_env("MAIL_FROM_NAME") || "David Maraga Campaign", from}
end

# Pick a real delivery adapter based on the env vars that are present.
# Brevo (HTTP API via Finch) takes priority, then Mailgun, then SMTP.
# The Local adapter is kept so the app still boots without mail credentials.
cond do
  System.get_env("BREVO_API_KEY") ->
    config :maraga_info, MaragaInfo.Mailer,
      adapter: Swoosh.Adapters.Brevo,
      api_key: System.get_env("BREVO_API_KEY")

    config :swoosh, :api_client, Swoosh.ApiClient.Finch
    config :swoosh, :finch_name, MaragaInfo.Finch

  System.get_env("MAILGUN_API_KEY") ->
    config :maraga_info, MaragaInfo.Mailer,
      adapter: Swoosh.Adapters.Mailgun,
      api_key: System.get_env("MAILGUN_API_KEY"),
      domain: System.get_env("MAILGUN_DOMAIN")

    config :swoosh, :api_client, Swoosh.ApiClient.Finch
    config :swoosh, :finch_name, MaragaInfo.Finch

  System.get_env("SMTP_RELAY") ->
    config :maraga_info, MaragaInfo.Mailer,
      adapter: Swoosh.Adapters.SMTP,
      relay: System.get_env("SMTP_RELAY"),
      username: System.get_env("SMTP_USERNAME"),
      password: System.get_env("SMTP_PASSWORD"),
      port: String.to_integer(System.get_env("SMTP_PORT") || "587"),
      tls: :always,
      auth: :always,
      retries: 2

  true ->
    :ok
end
