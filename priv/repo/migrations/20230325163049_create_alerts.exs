defmodule TurnStile.Repo.Migrations.CreateAlerts do
  use Ecto.Migration

  def change do
    create table(:alerts) do
      add :text, :string
      add :employee_id, references("employees"), null: false
      add :user_id, references("users"), null: false

      timestamps()
    end
  end
end
