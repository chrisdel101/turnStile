defmodule TurnStile.Repo.Migrations.AddAdminRoleTypes do
  use Ecto.Migration

  def change do
      # https://stackoverflow.com/a/37216214/5972531
      execute("create type admin_role as enum #{TurnStile.Utils.convert_to_parens_string(AdminPermissionRoles.get_admin_all_roles())}")

      execute("create type admin_role_value as enum #{TurnStile.Utils.convert_to_parens_string(Enum.map(RoleValuesMap.get_permission_role_values(), fn {_key, value} -> value end))}")

      execute("create type admin_client_type as enum #{TurnStile.Utils.convert_to_parens_string(ClientTypesEnum.get_client_types())}")

  end
end
