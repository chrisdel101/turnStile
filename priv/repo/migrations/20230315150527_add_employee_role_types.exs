defmodule TurnStile.Repo.Migrations.AddEmployeeRoleTypes do
  use Ecto.Migration

  def change do
      # https://stackoverflow.com/a/37216214/5972531
      execute("create type employee_role as enum #{TurnStile.Utils.convert_to_parens_string(EmployeePermissionRoles.get_employee_all_roles())}")

      execute("create type employee_role_value as enum #{TurnStile.Utils.convert_to_parens_string(Enum.map(RoleValuesEnum.get_permission_role_values(), fn {_key, value} -> value end))}")

      execute("create type employee_client_type as enum #{TurnStile.Utils.convert_to_parens_string(ClientTypesEnum.get_client_types())}")
      execute "CREATE EXTENSION IF NOT EXISTS citext", ""

  end
end
