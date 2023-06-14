defmodule TurnStile.AlertsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TurnStile.Alerts` context.
  """

  @doc """
  Generate a alert.
  """
  def alert_fixture(attrs \\ %{}) do
    {:ok, alert} =
      attrs
      |> Enum.into(%{

      })
      |> TurnStile.Alerts.create_alert()

    alert
  end
end
