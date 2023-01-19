defmodule TableTop.Repo do
  use Ecto.Repo,
    otp_app: :table_top,
    adapter: Ecto.Adapters.Postgres
end
