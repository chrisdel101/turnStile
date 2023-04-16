defmodule TurnStileWeb.AlertController do
  use TurnStileWeb, :controller

  def create(conn, _opts) do
    ExTwilio.Message.create(
      to: System.get_env("TEST_NUMBER"), from: System.get_env("TWILIO_PHONE_NUM"),
      body: "Hello"
    )
  end

end
