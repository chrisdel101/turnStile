defmodule TurnStileWeb.AlertController do
  use TurnStileWeb, :controller
  alias TurnStile.Utils
  alias TurnStile.Patients
  @json Utils.read_json("sms.json")

  # create alert; used for server side pages
  def create(conn, %{"employee_id" => employee_id, "user_id" => user_id}) do
    case ExTwilio.Message.create(
           to: System.get_env("TEST_NUMBER"),
           from: System.get_env("TWILIO_PHONE_NUM"),
           body: @json["alerts"]["request"]["initial"]
         ) do
      {:ok, _twilio_msg} ->
        conn
        |> put_flash(:info, "Alert sent successfully.")
        |> redirect(
          to:
            Routes.user_show_path(
              conn,
              :show,
              conn.assigns[:current_employee].organization_id,
              employee_id,
              user_id
            )
        )

      # handle twilio errors
      {:error, error_map, error_code} ->
        IO.inspect("error: #{error_code} #{error_map["message"]}")

        conn
        |> put_flash(:error, "Alert Failed: #{error_map["message"]}")
        |> redirect(
          to:
            Routes.organization_employee_user_path(
              conn,
              :index,
              conn.assigns[:current_employee].organization_id,
              employee_id
            )
        )

      true ->
        conn
        |> put_flash(:error, "An unknown error occured")
        |> redirect(
          to:
            Routes.organization_employee_user_path(
              conn,
              :index,
              conn.assigns[:current_employee].organization_id,
              employee_id
            )
        )
    end
  end

  # # live-view version- create and send the alert only
  # def create_live(%{"employee_id" => _employee_id, "user_id" => _user_id}) do
  #   case ExTwilio.Message.create(
  #          to: System.get_env("TEST_NUMBER"),
  #          from: System.get_env("TWILIO_PHONE_NUM"),
  #          body: @json["alerts"]["request"]["initial"]
  #        ) do
  #     {:ok, twilio_msg} ->
  #       {:ok, twilio_msg}
  #     # handle twilio errors
  #     {:error, error_map, error_code} ->
  #       {:error, error_map, error_code}
  #     true ->
  #       "An unknown error occured"
  #   end
  # end

  # handle incoming user response and render proper reply repsponse
  def receive(conn, twilio_params) do
    # is_response_valid(twilio_params)
    response = handle_sms_response(twilio_params)
    token = handle_alert_cookie_token(conn)
    IO.inspect(maybe_write_alert_cookie(conn, token), label: "maybe_write_alert_cookie")
    IO.inspect(twilio_params, label: "twilio_params")
    conn
    |> put_resp_content_type("text/xml")
    |> maybe_write_alert_cookie(token)
    |> text(IsolatedTwinML.render_response(response))
  end

  # check user resonse within text message
  def handle_sms_response(params) do
    # get response from text message
    body = params["Body"]

    #  check if match is valid or not
    if @json["matching_responses"][body] do
      # handle user account
      @json["matching_responses"][body]
    else
      @json["alerts"]["response"]["wrong_response"]
    end
  end

  def handle_alert_cookie_token(conn) do
    IO.inspect(conn)
    if !conn.cookies || conn.cookies === %{} do
      IO.puts("COOKIES EMPTY")
      # Alerts.generate_employee_session_token(alert)
      TurnStile.Alerts.AlertToken.build_cookie_token
      # create cookie
    else
      IO.puts("COOKIES EXIST")
      conn.cookies
    end
  end

  def handle_user_account_updates(params) do
    phone = params["From"]
    active_user = Patients.list_active_users()
  end

  def is_response_valid?(params) do
    # get response from text message
    body = params["Body"]
    #  check if match is valid or not
    if @json["matching_responses"][body], do: true, else: false
  end

  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_turn_stile_alert"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  defp maybe_write_alert_cookie(conn, token) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end
end

# isolate in separate module - duplicate render function in both causes ambiguity error
defmodule IsolatedTwinML do
  # alias TurnStile.Utils
  # @json Utils.read_json("sms.json")
  def render_response(response) do
    IO.inspect(response, label: "response")
    import ExTwiml

    # This TwiML module is required for the response as twilio expects TwiML https://www.twilio.com/docs/messaging/twiml for the body
    twiml do
      message do
        body(response)
      end
    end
  end
end
