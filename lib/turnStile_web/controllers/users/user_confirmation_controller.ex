defmodule TurnStileWeb.UserConfirmationController do
  use TurnStileWeb, :controller
  import Plug.Conn

  # alias TurnStile.Patients
  # alias TurnStile.Patients.User
  # alias TurnStileWeb.UserAuth
  # @json TurnStile.Utils.read_json("sms.json")


  def update(_conn, %{"_action" => "confirm"}) do
    # Handle confirm action
  end

  def update(_conn, %{"_action" => "cancel"}) do
    # Handle cancel action

  end

end
