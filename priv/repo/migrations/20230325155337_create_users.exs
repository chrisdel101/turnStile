defmodule TurnStile.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :first_name, :string
      add :last_name, :string
      add :email, :string
      add :phone, :string
      add :health_card_num, :integer

      timestamps()
    end
  end
end
