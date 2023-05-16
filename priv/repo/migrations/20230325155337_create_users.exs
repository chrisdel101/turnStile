defmodule TurnStile.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    execute("create type user_client_type as enum #{TurnStile.Utils.convert_to_parens_string(ClientTypesEnum.get_client_types())}")
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""
    create table(:users) do
      add :first_name, :string
      add :last_name, :string
      add :email, :citext
      add :client_type, :user_client_type
      add :phone, :string
      add :health_card_num, :integer
      add :employee_id, references("employees"), null: false

      timestamps()
    end
  end
end
