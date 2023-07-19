defmodule TurnStileWeb.UserConfirmationController do
  use TurnStileWeb, :controller

  # alias TurnStile.Patients
  # alias TurnStile.Patients.User
  # alias TurnStile.Patients.UserToken
  @json TurnStile.Utils.read_json("sms.json")
  def new(conn, %{"id" => alert_id, "token" => token}) do
      render(conn, "new.html", alert_id: alert_id, token: token, json: @json)
  end
  def update(conn, %{"_action" => "confirm"}) do
    # Handle confirm action
  end

  def update(conn, %{"_action" => "cancel"}) do
    # Handle cancel action

  end

end
