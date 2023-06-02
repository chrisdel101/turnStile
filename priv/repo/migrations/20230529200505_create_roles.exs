defmodule TurnStile.Repo.Migrations.CreateRoles do
  use Ecto.Migration

  def change do


    create table(:roles) do
      add :name, :employee_role, null: false
      add :value, :employee_role_value, null: false
      add :employee_id, references(:employees), null: false
      add :organization_id, references(:organizations), null: false


      timestamps()
    end
  end
  def down do
    drop table(:roles)
  end
end
