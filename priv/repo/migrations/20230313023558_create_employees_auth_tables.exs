defmodule TurnStile.Repo.Migrations.CreateEmployeesAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:employees) do
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
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
