defmodule TurnStile.Repo.Migrations.CreateOwners do
  use Ecto.Migration

  def change do
    create table(:owners) do
      add :first_name, :string
      add :last_name, :string
      add :employee_id, references(:employees, on_delete: :nothing), null: false
      add :organization_id, references("organizations"), null: false
      timestamps()
    end

    create index(:owners, [:employee_id])
  end
end
