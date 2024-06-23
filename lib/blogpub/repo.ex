defmodule Blogpub.Repo do
  use Ecto.Repo,
    otp_app: :blogpub,
    adapter: Ecto.Adapters.Postgres
end
