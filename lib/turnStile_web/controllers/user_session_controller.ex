defmodule TurnStileWeb.UserSessionController do
  use TurnStileWeb, :controller

  alias TurnStile.Patients
  alias TurnStileWeb.UserAuth
  @json TurnStile.Utils.read_json("sms.json")

  def new(conn, %{"user_id" => _user_id, "token" => token}) do
    current_user = conn.assigns[:current_user]

    if current_user do
      IO.inspect(current_user, label: "USER top")
      conn
      |> redirect(to: Routes.user_confirmation_path(conn, :new, current_user.id))
    else
      # check URL token - match url to hashed-token in DB
      case Patients.confirm_user_email_token(token) do
        {:ok, user} ->
          # IO.inspect(user, label: "USER")
          conn
          |> UserAuth.log_in_user(user)

        :not_found ->
          # no users matching
          IO.puts("user not_found: user_seesion_controller new")
          conn
          |> put_flash(:error, "Sorry, invalid or expired URL token.")
          |> redirect(to: "/")
      end
    end
  end
  # redirected here from above new/2
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
