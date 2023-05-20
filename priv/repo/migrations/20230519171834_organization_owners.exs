defmodule TurnStile.Repo.Migrations.OrganizationOwners do
  use Ecto.Migration

  def change do
    create table(:organization_owners) do
      add :organization_id, references(:organizations)
      add :owner_id, references(:owners)

      timestamps()
    end
    create unique_index(:organization_owners, [:organization_id, :owner_id])  end
end
