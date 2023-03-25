defmodule TurnStile.Repo.Migrations.CreateAlerts do
  use Ecto.Migration

  def change do
    create table(:alerts) do
      add :text, :string

      timestamps()
    end
  end
end
