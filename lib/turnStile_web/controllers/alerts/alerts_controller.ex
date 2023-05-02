defmodule TurnStileWeb.AlertController do
  use TurnStileWeb, :controller
  alias TurnStile.Utils
  @json Utils.read_json("sms.json")

  def create(conn, %{"employee_id" => employee_id, "user_id" => user_id}) do

  # case {:ok, "hello"} do
  case ExTwilio.Message.create(
      to: System.get_env("TEST_NUMBER"),
      from: System.get_env("TWILIO_PHONE_NUM"),
      body: @json["alert"]["initial"]
      ) do
      {:ok, _twilio_msg} ->
        conn
        |> put_flash(:info, "Alert sent successfully.")
        |> redirect(to: Routes.organization_employee_user_path(conn, :show, conn.assigns[:current_employee].organization_id, employee_id, user_id))
      # handle twilio errors
      {:error, error_map, error_code} ->
        IO.inspect(error_code)
        IO.inspect(error_map["message"])
        conn
        |> put_flash(:error, "Alert Failed: #{error_map["message"]}")
        |> redirect(to: Routes.organization_employee_user_path(conn, :index, conn.assigns[:current_employee].organization_id, employee_id))
      true ->
          conn
        |> put_flash(:error, "An unknown error occured")
        |> redirect(to: Routes.organization_employee_user_path(conn, :index, conn.assigns[:current_employee].organization_id, employee_id))
      end


  end

  def receive(conn, _params) do
    conn
    |> put_resp_content_type("text/xml")
    |> text(AnotherModule.render_response())
  end

end

defmodule AnotherModule do
  def render_response() do
    import ExTwiml

    # This TwiML module is required for the response as twilio expects TwiML https://www.twilio.com/docs/messaging/twiml for the body
    twiml do
      message do
        body("Hello222 world!")
      end
    end
  end
end
