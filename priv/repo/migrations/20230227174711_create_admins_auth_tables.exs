defmodule TurnStile.Repo.Migrations.CreateAdminsAuthTables do
  use Ecto.Migration

  # use constants.AdminRolesEnum


  def change do

    execute("create type roles as enum #{Enum.map(AdminRolesEnum.get_roles(), fn x -> Atom.to_string(x) end)}")

    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:admins) do
      add :first_name, :string
      add :last_name, :string
      # FIX: must be added as atom
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
