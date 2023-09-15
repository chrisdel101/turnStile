defmodule TurnStile.Repo.Migrations.CreateOrganizations do
  use Ecto.Migration

  def change do
    create table(:organizations) do
      add :name, :string
      add :slug, :string
      add :email, :string
      add :phone, :string
      add :timezone, :timezone
      add :require_init_employee_confirmation, :boolean
      add :employee_create_setup_is_required, :boolean
      add :employee_create_init_auto_login, :boolean
      add :employee_create_auto_login, :boolean
      add :employee_confirm_auto_login, :boolean
      add :user_allow_pending_into_queue, :boolean






      timestamps()
    end
  end
end
