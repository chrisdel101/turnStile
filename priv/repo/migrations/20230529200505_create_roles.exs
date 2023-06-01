defmodule TurnStile.Repo.Migrations.CreateRoles do
  use Ecto.Migration

  def change do
    execute("create type employee_role as enum #{TurnStile.Utils.convert_to_parens_string(EmployeePermissionRoles.get_employee_all_roles())}")

    execute("create type employee_role_value as enum #{TurnStile.Utils.convert_to_parens_string(Enum.map(RoleValuesEnum.get_permission_role_values(), fn {_key, value} -> value end))}")

    create table(:roles) do
      add :name, :employee_role, null: false
      add :value, :employee_role_value, null: false
      # add :organization_id, :integer
      add :employee_id, references(:employees), null: false
      add :organization_id, references(:organizations), null: false


      timestamps()
    end
  end
  def down do
    drop table(:roles)
  end
end
