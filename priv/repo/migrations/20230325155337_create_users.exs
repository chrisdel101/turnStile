defmodule TurnStile.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do

    execute "CREATE EXTENSION IF NOT EXISTS citext", ""
    create table(:users) do
      add :first_name, :string
      add :last_name, :string, null: false
      add :email, :citext
      add :phone, :string
      add :health_card_num, :integer
      add :is_active?, :boolean
      add :status, :string
      add :employee_id, references("employees"), null: false
      add :organization_id, references("organizations"), null: false

      timestamps()
    end
  end
end
