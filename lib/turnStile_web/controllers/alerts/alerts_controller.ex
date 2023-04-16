defmodule TurnStileWeb.AlertController do
  use TurnStileWeb, :controller

  def create(conn, %{"employee_id" => employee_id, "user_id" => user_id}) do
  case ExTwilio.Message.create(
      to: System.get_env("TEST_NUMBER1"), from: System.get_env("TWILIO_PHONE_NUM"),
      body: "Hello"
      ) do
      {:ok, message} ->
        conn
        |> put_flash(:info, "Alert sent successfully.")
        |> redirect(to: Routes.organization_employee_user_path(conn, :show, conn.assigns[:current_employee].organization_id, employee_id, user_id))
      # handle twilio errors
      {:error, error_map, error_code} ->
        IO.inspect(error_code)
        IO.inspect(error_map["message"])
        conn
        |> put_flash(:error, "Alert Failed:   #{error_map["message"]}")
        |> redirect(to: Routes.organization_employee_user_path(conn, :index, conn.assigns[:current_employee].organization_id, employee_id))
      true ->
          conn
        |> put_flash(:error, "An unknown error occured")
        |> redirect(to: Routes.organization_employee_user_path(conn, :index, conn.assigns[:current_employee].organization_id, employee_id))
      end

    conn

  end

end
