defmodule TurnStile.Repo.Migrations.CreateAdminsAuthTables do
  use Ecto.Migration

  def change do
    execute("create type admin_role as enum #{TurnStile.Utils.convert_to_parens_string(AdminPermissionRoles.get_admin_all_roles())}")
    execute("create type admin_client_type as enum #{TurnStile.Utils.convert_to_parens_string(ClientTypesEnum.get_client_types())}")
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:admins) do
      add :first_name, :string
      add :last_name, :string
      # role/client_type created above - each needs two diff names
      add :client_type, :admin_client_type, null: false, default: ClientTypesEnum.get_client_type_value("admin")
      add :role, :admin_role, null: false
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps()
    end

    create unique_index(:admins, [:email])

    create table(:admins_tokens) do
      add :admin_id, references(:admins, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:admins_tokens, [:admin_id])
    create unique_index(:admins_tokens, [:context, :token])
  end
  def down do
    execute "drop type admin_role"
    execute "drop type client_type"
  end
end
