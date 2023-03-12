defmodule TurnStile.Repo.Migrations.CreateAdminsAuthTables do
  use Ecto.Migration
  def change do
    # https://stackoverflow.com/a/37216214/5972531
    execute("create type role as enum #{TurnStile.Utils.convert_to_parens_string(EmployeeRolesEnum.get_roles())}")
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:admins) do
      add :first_name, :string
      add :last_name, :string
      # role created above can be used here
      add :role, :role, null: false
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

end
