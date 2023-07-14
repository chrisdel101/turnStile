defmodule TurnStileWeb.AlertController do
  use TurnStileWeb, :controller
  alias TurnStile.Utils
  alias TurnStile.Patients
  alias TurnStileWeb.AlertUtils
  alias TurnStile.Alerts.Alert
  alias TurnStile.Alerts
  @json Utils.read_json("sms.json")

  def receive_sms_alert(conn, twilio_params) do
    # IO.inspect(twilio_params, label: "twilio_params")
    if is_response_valid?(twilio_params) do
      case match_recieved_sms_to_user(twilio_params) do
        {:ok, user} ->
          # IO.inspect(user, label: "USER")
          case AlertUtils.save_received_alert(user, twilio_params) do
            {:ok, alert} ->
              IO.inspect(alert, label: "alert")
              # exract response text
              response_body = compute_sms_return_body(twilio_params)
              # build response map
              response_map = Alerts.build_system_response_map(alert, body: response_body)
              # update alert w system_response map; recieved alerts only
              case Alerts.update_alert(alert, response_map) do
                {:ok, updated_alert} ->
                  IO.inspect(updated_alert, label: "updated_alert")
                  # update user account
                  case handle_receive_alert_user_update(user, twilio_params) do
                    {:ok, updated_user} ->
                      IO.inspect(updated_user, label: "updated_user")
                        # physically send resonse
                      send_computed_system_response(conn, twilio_params)

                    {:error, error} ->
                      IO.inspect(error, label: "receive_sms_alert error in update_user")
                      send_manual_system_response(conn, "An account update error occurred. Account not updated.")

                  end
                {:error, error} ->
                  IO.inspect(error, label: "receive_sms_alert error in update_alert")
                  send_manual_system_response(conn, "An account update error occurred. Account not updated.")
              end

              {:error, error} ->
                IO.inspect(error, label: "receive_sms_alert error in save_received_alert")
                send_manual_system_response(conn, "An account save error occurred. Account not updated.")
          end

        {:error, error} ->
          IO.inspect(error, label: "ERROR")
          send_manual_system_response(conn, "Error: User account not found.")
      end
    else
      # Invalid response user response; send notification; msg is set in json
      send_computed_system_response(conn, twilio_params)
    end
  end

  # twlilio webhook in resonse to user reply
  def send_computed_system_response(conn, twilio_params) do
    IO.puts("SENDING REPLY")
    conn
    |> put_resp_content_type("text/xml")
    # |> maybe_write_alert_cookie(token)
    |> text(IsolatedTwinML.render_response(compute_sms_return_body(twilio_params)))
  end

  # twlilio webhook in resonse to user reply
  def send_manual_system_response(conn, response_body) do
    IO.puts("SENDING REPLY")
    conn
    |> put_resp_content_type("text/xml")
    # |> maybe_write_alert_cookie(token)
    |> text(IsolatedTwinML.render_response(response_body))
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
            {:ok, hd(active_users)}
        end

      length(users_w_number) === 1 ->
        {:ok, hd(users_w_number)}

      true ->
        error = "Error: a problem occured looking up matching user"
        {:error, error}
    end
  end

  # check user resonse within text message; find appropriate response to send
  def compute_sms_return_body(twilio_params) do
    # get response from text message
    body = twilio_params["Body"]

    #  check if match is valid or not
    if @json["matching_responses"][body] do
      # handle user account
      @json["matching_responses"][body]
    else
      @json["alerts"]["response"]["wrong_response"]
    end
  end
#  - must use arrows to match twilio params
  def handle_receive_alert_user_update(user, twilio_params) do
    body = twilio_params["Body"]
    #  check if match is valid or not
    if @json["matching_responses"][body] do
      IO.inspect(body, label: "body")
      cond do
        body === "1" ->
          # save alert

          # update user account
          Patients.update_alert_status(user, UserAlertStatusTypesMap.get_user_status("CONFIRMED")
          )

        body === "2" ->
          # update user account
          Patients.update_alert_status(user, UserAlertStatusTypesMap.get_user_status("CANCELLED")
          )

        true ->
          {:error, "Error: invalid response in handle_receive_alert_user_update"}
      end
    end
  end

  def handle_receive_alert_system_response_update(alert, response_body, opts \\ []) do
    system_response = %{
      system_response: %{
        title: Keyword.get(opts, :title, "System Response"),
        body: response_body,
        to: alert.from,
        from: alert.to,
        alert_format: AlertFormatTypesMap.get_alert("SMS")
      }
    }
    Alerts.update_alert(alert, system_response)
  end

  defp is_response_valid?(params) do
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
