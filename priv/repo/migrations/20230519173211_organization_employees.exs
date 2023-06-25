defmodule TurnStile.Repo.Migrations.OrganizationEmployees do
  use Ecto.Migration

  def change do
    create table(:organization_employees, primary_key: false) do
      add :organization_id, references(:organizations, on_delete: :delete_all, primary_key: true)
      add :employee_id, references(:employees, on_delete: :delete_all, primary_key: true)
      add :inserted_at, :naive_datetime, default: fragment("CURRENT_TIMESTAMP"), null: false
    end
    create unique_index(:organization_employees, [:organization_id, :employee_id])

  end
end
