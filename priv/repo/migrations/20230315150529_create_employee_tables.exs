defmodule TurnStile.Repo.Migrations.CreateEmployeesAuthTables do
  use Ecto.Migration
  def change do

    create table(:employees) do
      add :first_name, :string
      add :last_name, :string
      # role/client_type created above - each needs two diff names
      add :client_type, :employee_client_type, null: false, default: ClientTypesEnum.get_client_type_value("employee")
      add :current_organization_login_id, :integer
      add :role_value_on_current_organization, :employee_role_value
      add :role_on_current_organization, :employee_role
      add :is_logged_in?, :boolean
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
