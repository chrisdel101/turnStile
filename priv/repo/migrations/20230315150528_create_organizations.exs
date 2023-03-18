defmodule TurnStile.Repo.Migrations.CreateOrganizations do
  use Ecto.Migration

  def change do
    create table(:organizations) do
      add :name, :string
      add :slug, :string
      add :email, :string
      add :phone, :string

      timestamps()
    end
  end
end
