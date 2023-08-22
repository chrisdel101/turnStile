
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
    a = AlertController.receive_email_alert(conn, %{"user_id" => user_id, "response_value" => @confirm_value, "response_key" => @confirm_key})
    IO.inspect(a, label: "a")
    # Handle confirm action
    case AlertController.receive_email_alert(conn, %{"user_id" => user_id, "response_value" => @confirm_value, "response_key" => @confirm_key}) do
      {:ok, alert} ->
        conn
        |> put_flash(:success, alert.system_response.body)
        |> redirect(to: Routes.user_session_path(conn, :new, user_id))

      {:error, error_msg} ->
        conn
        |> put_flash(:error, error_msg)
        |> redirect(to: Routes.user_session_path(conn, :new, user_id))
      nil ->
        conn
        |> redirect(to: Routes.user_session_path(conn, :new, user_id))
    end
  end

  def update(conn, %{"_action" => "cancel", "user_id" => user_id}) do
    # Handle cancel action
    case AlertController.receive_email_alert(conn, %{"user_id" => user_id, "response_value" => @cancel_value, "response_key" => @cancel_key}) do
      {:ok, alert} ->
        # deactivate user; remove from queue

        TurnStile.Patients.deactivate_user(Patients.get_user(user_id))
        conn
        |> put_flash(:warning, alert.system_response.body)
        |> UserAuth.log_out_user()

      {:error, error_msg} ->
        conn
        |> put_flash(:error, error_msg)
        |> redirect(to: Routes.user_session_path(conn, :new, user_id))
    end
  end

end