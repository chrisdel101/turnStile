defmodule TurnStile.Repo.Migrations.AddUserAlertStatusTypes do
  use Ecto.Migration

  def change do
      # https://stackoverflow.com/a/37216214/5972531
      execute("create type user_alert_status as enum #{TurnStile.Utils.convert_to_parens_string( UserAlertStatusTypesMap.get_user_statuses_enum)}")

  end
end
