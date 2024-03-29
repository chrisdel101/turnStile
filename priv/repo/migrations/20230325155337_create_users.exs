defmodule TurnStile.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do

    execute "CREATE EXTENSION IF NOT EXISTS citext", ""
    create table(:users) do
      add :first_name, :string
      add :last_name, :string, null: false
      add :email, :citext
      add :phone, :string
      add :health_card_num, :bigint
      add :date_of_birth, :date
      add :is_active?, :boolean
      add :user_alert_status, :user_alert_status
      add :alert_format_set, :alert_format
      add :account_confirmed_at, :naive_datetime
      add :conf_alert_recieved_at, :naive_datetime
      add :activated_at, :naive_datetime
      add :deactivated_at, :naive_datetime
      add :queued_at, :naive_datetime
      add :employee_id, references("employees", on_delete: :delete_all), null: false
      add :organization_id, references("organizations", on_delete: :delete_all), null: false

      timestamps()
    end
    create unique_index(:users, [:health_card_num])
    create unique_index(:users, [:phone, :alert_format_set, :is_active?])

    create table(:user_tokens) do
      add :user_id, references(:users, on_delete: :delete_all) # remmove null:false to allow for verication tokens
      add :organization_id, references(:organizations, on_delete: :delete_all)
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end
    create index(:user_tokens, [:user_id])
    create unique_index(:user_tokens, [:context, :token])
  end
end
