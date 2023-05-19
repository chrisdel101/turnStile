defmodule TurnStile.Repo.Migrations.CreateOwners do
  use Ecto.Migration

  def change do
    create table(:owners) do
      add :first_name, :string
      add :last_name, :string
      add :organization_id, references("organizations"), null: false
      add :employee_id, references(:employees, on_delete: :delete_all), null: false
      timestamps()
    end

    create index(:owners, [:employee_id])
  end
end
