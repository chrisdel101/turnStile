defmodule TurnStileWeb.UserConfirmationController do
  use TurnStileWeb, :controller
  import Plug.Conn

  alias TurnStileWeb.AlertController

  @confirm_value "1"
  @confirm_key "CONFIRMATION"
  @cancel_value "2"
  @cancel_key "CANCELLATION"

  def update(conn, %{"_action" => "confirm", "user_id" => user_id}) do
    # Handle confirm action
    case AlertController.receive_email_alert(conn, %{"user_id" => user_id, "response_value" => @confirm_value, "response_key" => @confirm_key}) do
      {:ok, system_response_body} ->
        conn
        |> put_flash(:success, system_response_body)
        |> redirect(to: Routes.user_session_path(conn, :new, user_id))

      {:error, error_msg} ->
        conn
        |> put_flash(:error, error_msg)
        |> redirect(to: Routes.user_session_path(conn, :new, user_id))
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "An error occured")
        |> redirect(to: Routes.user_session_path(conn, :new, user_id))
    end
  end

  def update(conn, %{"_action" => "cancel", "user_id" => user_id}) do
    # Handle cancel action
    case AlertController.receive_email_alert(conn, %{"user_id" => user_id, "response_value" => @cancel_value, "response_key" => @cancel_key}) do
      {:ok, system_response_body} ->
        conn
        |> put_flash(:success, system_response_body)
        |> redirect(to: Routes.user_session_path(conn, :new, user_id))

      {:error, error_msg} ->
        conn
        |> put_flash(:error, error_msg)
        |> redirect(to: Routes.user_session_path(conn, :new, user_id))
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "An error occured")
        |> redirect(to: Routes.user_session_path(conn, :new, user_id))
    end
  end

end
