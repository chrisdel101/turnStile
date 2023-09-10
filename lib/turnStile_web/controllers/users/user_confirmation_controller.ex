
defmodule TurnStileWeb.UserConfirmationController do
  @moduledoc """
    UserConfirmationController
  - after user is verified, they are sent to this controller to handle intreactions with application
  - used to interact with their alerts
  """
  use TurnStileWeb, :controller
  import Plug.Conn

  alias TurnStileWeb.AlertController
  alias TurnStile.Patients
  alias TurnStileWeb.UserAuth

  @confirm_value "1"
  @confirm_key "CONFIRMATION"
  @cancel_value "2"
  @cancel_key "CANCELLATION"


  def update(conn, %{"_action" => "confirm", "user_id" => user_id}) do
    current_user = conn.assigns.current_user
    a = AlertController.receive_email_alert(conn, %{"user_id" => user_id, "response_value" => @confirm_value, "response_key" => @confirm_key})
    IO.inspect(a, label: "a")
    # Handle confirm action
    case AlertController.receive_email_alert(conn, %{"user_id" => user_id, "response_value" => @confirm_value, "response_key" => @confirm_key}) do
      {:ok, alert} ->
        conn
        |> put_flash(:success, alert.system_response.body)
        |> redirect(to: Routes.user_session_path(conn, :new, current_user.organization_id, user_id))

      {:error, error_msg} ->
        conn
        |> put_flash(:error, error_msg)
        |> redirect(to: Routes.user_session_path(conn, :new,
        current_user.organization_id, user_id))
      # if indentical actio is sent do nothing
      {:no_action} ->
        conn
      nil ->
        conn
        |> redirect(to: Routes.user_session_path(conn, :new, current_user.organization_id,
        user_id))
    end
  end

  def update(conn, %{"_action" => "cancel", "user_id" => user_id}) do
    current_user = conn.assigns.current_user
    # Handle cancel action
    case AlertController.receive_email_alert(conn, %{"user_id" => user_id, "response_value" => @cancel_value, "response_key" => @cancel_key}) do
      {:ok, alert} ->
        # deactivate user; remove from queue

        TurnStile.Patients.deactivate_user(Patients.get_user(user_id, current_user.organization_id))
        conn
        |> put_flash(:warning, alert.system_response.body)
        |> UserAuth.log_out_user()

      {:error, error_msg} ->
        conn
        |> put_flash(:error, error_msg)
        |> redirect(to: Routes.user_session_path(conn, :new,
        current_user.organization_id, user_id))
       # if indentical actio is sent do nothing
       {:no_action} ->
        conn
    end
  end

end
