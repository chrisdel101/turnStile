defmodule TurnStile.Repo.Migrations.AddPostgresExtensions do
  use Ecto.Migration

  def change do
    execute("create extension fuzzystrmatch")

  end
end
