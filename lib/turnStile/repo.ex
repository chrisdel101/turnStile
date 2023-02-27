defmodule TurnStile.Repo do
  use Ecto.Repo,
    otp_app: :turnStile,
    adapter: Ecto.Adapters.Postgres
end
