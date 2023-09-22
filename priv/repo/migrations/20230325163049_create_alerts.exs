defmodule TurnStile.Repo.Migrations.CreateAlerts do
  use Ecto.Migration

  def change do
    create table(:alerts) do
      add :title, :string
      add :body, :string
      add :to, :string, null: false
      add :from, :string, null: false
      add :alert_category, :alert_category, null: false
      add :alert_format, :alert_format, null: false
      add :employee_id, references("employees", null: false, on_delete: :delete_all)
      add :user_id, references("users", null: false, on_delete: :delete_all)
      add :organization_id, references("organizations",on_delete: :delete_all)
      add :system_response, :map  # tracks webhooks responses

      timestamps()
    end

      create table(:alert_tokens) do
        add :alert_id, references(:alerts, on_delete: :delete_all), null: false
        add :token, :binary, null: false
        add :context, :string, null: false
        add :sent_to, :string
        timestamps(updated_at: false)
      end

      create index(:alert_tokens, [:alert_id])
      create unique_index(:alert_tokens, [:context, :token])
    end

end
