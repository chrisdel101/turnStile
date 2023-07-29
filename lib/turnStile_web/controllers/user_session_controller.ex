defmodule TurnStileWeb.UserSessionController do
  alias TurnStile.Patients.UserToken
  use TurnStileWeb, :controller

  alias TurnStile.Patients
  alias TurnStileWeb.UserAuth
  @json TurnStile.Utils.read_json("sms.json")

  # handle_validate_email_token
  # - handles request if user if not logged yet
  # - if logged in user calls this redirect them to new/1 below
  # - else confirm email token + log in and redirect to new/1
  # - if not confirmed email send err val and redirect
  # - handles all cases of email token errors
  # - if email token expired sends status update to UI
  def handle_validate_email_token(conn, %{"user_id" => user_id, "token" => encoded_token}) do
    current_user = conn.assigns[:current_user]

    if current_user do
      conn
      |> redirect(to: Routes.user_session_path(conn, :new, current_user.id))
    else
      # check URL encoded_token - match url to hashed-token in DB
      case Patients.confirm_user_email_token(encoded_token, user_id) do
        {:ok, user} ->
          # IO.inspect(user, label: "USER")
          conn
          # log in and set session token for future requests
          |> UserAuth.log_in_user(user)
          |> redirect(to: UserAuth.signed_in_main_path(conn, user) || get_session(conn, :user_return_to) )


        {nil, :not_matched} ->
           # user does match but - url :id is not correct for user token
          IO.puts("user_session_controller: user not_matched: User param :id does not match the token user id")
           conn
           |> put_flash(:error, "Sorry, your URL link has errors. Verify it is correct and try again, or contact your provider for a new link.")
           |> redirect(to: "/")
        {nil, :not_found} ->
          # no users matching - b/c user session does not match any users
          IO.puts("user_session_controller:  not_found")
          conn
          |> put_flash(:error, "Sorry, your URL link is invalid.")
          |> redirect(to: "/")
        :invalid_input_token ->
          # error on func call - b/c user has a malfromed URL i.e. extra quote at end
          IO.puts("user_session_controller:  :invalid_input_token")
          conn
          |> put_flash(:error, "Sorry, your URL link contains errors and is invalid. Confirm it is correct and try again, or contact your provider for a new link.")
          |> redirect(to: "/")
        {nil, :expired} ->
           # valid request but expired - will be deleted on this call
          # fetch full user token struct
          {:ok, query}  = UserToken.encoded_token_and_context_query(encoded_token, "confirm")
          user_token = TurnStile.Repo.one(query)
          # delete expirted token
          Patients.delete_email_token(user_token)
          IO.puts("user_session_controller:  token expired and deleted")
          # update user alert status
          user = Patients.get_user(user_id)
          {:ok, updated_user} = Patients.update_alert_status(user,UserAlertStatusTypesMap.get_user_status("EXPIRED"))
          # send respnse to update UI; match the DB status - opts pushes it to index liveView handler
          Phoenix.PubSub.broadcast(
          TurnStile.PubSub,
          PubSubTopicsMap.get_topic("STATUS_UPDATE"),
          %{user_alert_status: updated_user.user_alert_status})

          conn
          |> put_flash(:error, "Sorry, your link has expired. Contact your provider to resend a new link.")
          |> redirect(to: "/")
      end
    end
  end

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
