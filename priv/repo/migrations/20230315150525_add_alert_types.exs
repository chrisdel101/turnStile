defmodule TurnStile.Repo.Migrations.AddAlertTypes do
  use Ecto.Migration

  def change do
      # https://stackoverflow.com/a/37216214/5972531
      execute("create type alert_format as enum #{TurnStile.Utils.convert_to_parens_string(AlertFormatTypesMap.get_alerts_enum())}")

      execute("create type alert_category as enum #{TurnStile.Utils.convert_to_parens_string(AlertCategoryTypesMap.get_alerts_enum())}")

  end
end
