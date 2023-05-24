defmodule TurnStile.Repo.Migrations.OrganizationEmployees do
  use Ecto.Migration

  def change do
    create table(:organization_employees) do
      add :organization_id, references(:organizations)
      add :employee_id, references(:employees)
      add :inserted_at, :naive_datetime, default: fragment("CURRENT_TIMESTAMP"), null: false
    end
    create unique_index(:organization_employees, [:organization_id, :employee_id])

  end
end
