defmodule TurnStile.Repo.Migrations.CreateEmployeesAuthTables do
  use Ecto.Migration
  def change do
    # https://stackoverflow.com/a/37216214/5972531
    # execute("create type employee_role as enum #{TurnStile.Utils.convert_to_parens_string(EmployeePermissionRoles.get_employee_all_roles())}")

    # execute("create type employee_role_value as enum #{TurnStile.Utils.convert_to_parens_string(Enum.map(RoleValuesEnum.get_permission_role_values(), fn {_key, value} -> value end))}")

    execute("create type employee_client_type as enum #{TurnStile.Utils.convert_to_parens_string(ClientTypesEnum.get_client_types())}")
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:employees) do
      add :first_name, :string
      add :last_name, :string
      # role/client_type created above - each needs two diff names
      add :client_type, :employee_client_type, null: false, default: ClientTypesEnum.get_client_type_value("employee")
      # add :role, :employee_role, null: false
      # add :role_value, :employee_role_value
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps()
    end

    create unique_index(:employees, [:email])

    create table(:employee_tokens) do
      add :employee_id, references(:employees, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:employee_tokens, [:employee_id])
    create unique_index(:employee_tokens, [:context, :token])
  end

end
