defmodule TurnStile.Repo.Migrations.CreateRoles do
  use Ecto.Migration

  def change do


    create table(:roles) do
      add :name, :employee_role, null: false
      add :value, :employee_role_value, null: false
      add :organization_id, references(:organizations), on_delete: :delete_all
      add :employee_id, references(:employees), on_delete: :delete_all

      timestamps()
    end
    # # flush to make sure table exists
    # flush()
    # # insert roles values to be used
    # predefined_roles = EmployeeRolesMap.get_permission_role_values()
    # Enum.each(predefined_roles, fn {role_name, role_value} ->
    #   TurnStile.Repo.insert(%TurnStile.Roles.Role{name: role_name, value: to_string(role_value)})
    # end)
  end

  def down do
    drop table(:roles)
  end
end
