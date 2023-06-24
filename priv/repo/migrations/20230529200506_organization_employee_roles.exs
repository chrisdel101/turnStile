defmodule TurnStile.Repo.Migrations.OrganizationEmployeeRoles do
  use Ecto.Migration

  def change do
    create table(:organization_employee_roles) do
      add :organization_id, references(:organizations, on_delete: :delete_all)
      add :employee_id, references(:employees, on_delete: :delete_all)
      add :role_id, references(:roles, on_delete: :delete_all)
      add :inserted_at, :naive_datetime, default: fragment("CURRENT_TIMESTAMP"), null: false
    end
    create unique_index(:organization_employee_roles, [:organization_id, :employee_id, :role_id])

  end
end
