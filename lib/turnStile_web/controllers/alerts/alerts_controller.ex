defmodule TurnStileWeb.AlertController do
  use TurnStileWeb, :controller
  alias TurnStile.Utils
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
  def receive(conn, _params) do
    response = handle_response(conn)

    conn
    |> put_resp_content_type("text/xml")
    |> text(IsolatedTwinML.render_response(response))
  end

  # check user resonse within text message
  def handle_response(conn) do
    # get response from text message
    body = conn.params["Body"]
    #  if matche is valid, or not
    if @json["matching_responses"][body] do
      @json["matching_responses"][body]
    else
      @json["alerts"]["response"]["wrong_response"]
    end
  end
end

# isolate in separate module - duplicate render function in both causes ambiguity error
defmodule IsolatedTwinML do
  # alias TurnStile.Utils
  # @json Utils.read_json("sms.json")
  def render_response(response) do
    import ExTwiml

    # This TwiML module is required for the response as twilio expects TwiML https://www.twilio.com/docs/messaging/twiml for the body
    twiml do
      message do
        body(response)
      end
    end
  end
end
