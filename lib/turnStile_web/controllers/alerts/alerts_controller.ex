defmodule TurnStileWeb.AlertController do
  use TurnStileWeb, :controller
  alias TurnStile.Utils
  alias TurnStile.Patients
  @json Utils.read_json("sms.json")


  def receive_sms_alert(conn, twilio_params) do
    # IO.inspect(twilio_params, label: "twilio_params")
    if is_response_valid?(twilio_params) do
      case match_recieved_sms_to_user(twilio_params) do
        {:ok, user} ->
          IO.puts('USER')
          {:error, error} ->
            IO.puts('ERROR')
      end
      conn
      |> put_resp_content_type("text/xml")
      # |> maybe_write_alert_cookie(token)
      |> text(IsolatedTwinML.render_response(handle_sms_response(twilio_params)))
    else
        # Invalid response user response - send notification
        conn
        |> put_resp_content_type("text/xml")
        # |> maybe_write_alert_cookie(token)
        |> text(IsolatedTwinML.render_response(handle_sms_response(twilio_params)))
      end
  end
  @doc """
  match_recieved_sms_to_user
  -handles incoming SMS messages from Twilio-
  -only available useful param is phone number
  -checks for user w phone; gets last updated active user if multiple
  -TODO: if multiple active users active now, reqiuire employee action to resolve
  """
  def match_recieved_sms_to_user(twilio_params) do
      # remove starting "+"
      number =
        if String.starts_with?(twilio_params["From"], "+") do
          # Remove plus sign - change outer number
          String.slice(twilio_params["From"], 1..-1)
        else
          twilio_params["From"]
        end
      # IO.inspect(number, label: "number")
      users_w_number = Patients.get_users_by_phone(number)
      # IO.inspect(users_w_number, label: "users_w_number")
      cond do
        # if more than one use w that number
        list_is_greater_than_1(users_w_number) ->
          # check if active
          active_users = Utils.filter_maps_list(users_w_number, "is_active?")
          case list_is_greater_than_1(active_users) do
            true ->
              # check account most recently updated
              # TODO: check if active within window for mutliple active users
              last_active = Patients.check_last_account_update(active_users)
              {:ok, last_active}
            false ->
              # return only user
              {:ok, hd active_users}
          end
        length(users_w_number) === 1 ->
          {:ok, hd users_w_number}
        true ->
          error = "Error: a problem occured looking up matching user"
          {:error, error}
      end
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

  defp list_is_greater_than_1(list) do
    length(list) !== 0 && length(list) > 1
  end
end

# isolate in separate module - duplicate render function in both causes ambiguity error
defmodule IsolatedTwinML do
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
