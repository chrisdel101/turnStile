defmodule TurnStileWeb.UserSessionController do
  use TurnStileWeb, :controller

  alias TurnStile.Patients
  alias TurnStileWeb.UserAuth
  @json TurnStile.Utils.read_json("sms.json")

  def new(conn, %{"user_id" => user_id, "token" => token}) do
    current_user = conn.assigns[:current_user]

    if current_user do
      IO.inspect(current_user, label: "USER top")
      conn
      |> redirect(to: Routes.user_confirmation_path(conn, :new, current_user.id))
    else
      # check URL token - match url to hashed-token in DB
      case Patients.confirm_user_email_token(token, user_id) do
        {:ok, user} ->
          # IO.inspect(user, label: "USER")
          conn
          # log in and set session token for future requests
          |> UserAuth.log_in_user(user, %{"expirtation" => "true"})

        {nil, :not_matched} ->
           IO.puts("user not_matched: User param ID does not match the token")
           conn
           |> put_flash(:error, "Sorry, your URL link has matching errors. Verify it is correct and try again.")
           |> redirect(to: "/")
        {nil, :not_found} ->
          # no users matching
          IO.puts("user not_found: user_seesion_controller new")
          conn
          |> put_flash(:error, "Sorry, your URL link is invalid.")
          |> redirect(to: "/")
          {nil, :expired} ->
            IO.puts("token expired: user_seesion_controller new")
            user = Patients.get_user_by_id(user_id)
            {:ok, updated_user} = Patients.update_alert_status(user,UserAlertStatusTypesMap.get_user_status("EXPIRED"))
            IO.inspect(updated_user, label: "updated_user")
           Phoenix.PubSub.broadcast(
            TurnStile.PubSub,
            PubSubTopicsMap.get_topic("STATUS_UPDATE"),
            %{user_alert_status: updated_user.user_alert_status}
                      )
           conn
           |> put_flash(:error, "Sorry, your link has expired. Contact your provider to resend a new link.")
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
