defmodule TurnStileWeb.UserSessionController do
  use TurnStileWeb, :controller

  alias TurnStileWeb.UserAuth
  @json TurnStile.Utils.read_json("sms.json")


  def new(conn, %{"user_id" => _user_id}) do
    user = conn.assigns[:current_user]

    conn
    |> render("new.html", json: @json, user: user)
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end

end
