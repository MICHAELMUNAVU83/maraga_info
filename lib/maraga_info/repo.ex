defmodule MaragaInfo.Repo do
  use Ecto.Repo,
    otp_app: :maraga_info,
    adapter: Ecto.Adapters.Postgres
end
