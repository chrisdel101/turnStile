defmodule TurnStile.Repo.Migrations.CreateEmployeesAuthTables do
  use Ecto.Migration

  def change do
    # https://stackoverflow.com/a/37216214/5972531
    execute("create type employee_role as enum #{TurnStile.Utils.convert_to_parens_string(EmployeeRolesEnum.get_roles())}")
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:employees) do
      add :first_name, :string
      add :last_name, :string
      # role created above can be used here
      add :role, :employee_role, null: false
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      add :admin_id, references("admins"),  null: false
      timestamps()
    end

    create unique_index(:employees, [:email])

    create table(:employees_tokens) do
      add :employee_id, references(:employees, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:employees_tokens, [:employee_id])
    create unique_index(:employees_tokens, [:context, :token])
  end
end
