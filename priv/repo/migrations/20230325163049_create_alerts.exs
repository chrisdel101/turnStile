defmodule TurnStile.Repo.Migrations.CreateAlerts do
  use Ecto.Migration

  def change do
    create table(:alerts) do
      add :title, :string
      add :body, :string
      add :to, :string
      add :from, :string
      add :alert_category, :alert_category, null: false
      add :alert_format, :alert_format, null: false
      add :employee_id, references("employees"), null: false
      add :user_id, references("users"), null: false
      add :organization_id, references("organizations")

      timestamps()
    end
  end
end
