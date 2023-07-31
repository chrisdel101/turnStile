defmodule TurnStileWeb.AlertController do
  use TurnStileWeb, :controller
  alias TurnStile.Utils
  alias TurnStile.Patients
  alias TurnStileWeb.AlertUtils
  alias TurnStile.Alerts
  @json Utils.read_json("alert_text.json")

  def receive_email_alert(conn, %{
        "user_id" => user_id,
        "response_value" => response_value,
        "response_key" => response_key
      }) do
    current_user = conn.assigns[:current_user]

    # IO.inspect(response_value, label: "response_value")
    if is_response_valid?(response_value, AlertFormatTypesMap.get_alert("EMAIL")) do
      case AlertUtils.save_received_email_alert(
             current_user,
             %{"response_value" => response_value, "response_key" => response_key}
           ) do
        {:error, error_msg} ->
          # alert save failure
          IO.inspect(error_msg, label: "receive_email_alert error in save_received_email_alert")
          # update user account as ERROR status in DB
          case Patients.update_alert_status(
                 current_user,
                 UserAlertStatusTypesMap.get_user_status("ERROR")
               ) do
            {:ok, updated_user} ->
              # IO.inspect(updated_user, label: "updated_user")
              # send respnse to update UI, match DB
              Phoenix.PubSub.broadcast(
                TurnStile.PubSub,
                PubSubTopicsMap.get_topic("STATUS_UPDATE"),
                %{user_alert_status: updated_user.user_alert_status}
              )

            # udate user account error failure
            {:error, error} ->
              IO.inspect(error, label: "Attempt to update acount as ERROR failed.")
          end
          # outer return error for above case
          {:error, error_msg} # alert save failure return

        {:error, %Ecto.Changeset{} = changeset} ->
          {:error, changeset}

        {:ok, alert} ->
          # IO.inspect(alert, label: "receive_email_alert alert saved")
          system_response_body = compute_return_body(response_value, AlertFormatTypesMap.get_alert("EMAIL"))

          system_response_map =
            Alerts.build_system_response_map(alert, body: system_response_body)

          # IO.inspect(system_response_map, label: "receive_email_alert sytem_response_map")
          #  alert w system_response map; recieved alerts only
          case Alerts.update_alert(alert, system_response_map) do
            {:ok, updated_alert} ->
              # IO.inspect(updated_alert, label: "receive_email_alert updated_alert w system_response_map")

              user_alert_status = compute_user_alert_status(response_value)
              # update user account in DB
              case Patients.update_alert_status(current_user, user_alert_status) do
                {:ok, updated_user} ->
                  # IO.inspect(updated_user, label: "updated_user")
                  # send valid respnse to update UI - changes status on the page to match
                  Phoenix.PubSub.broadcast(
                    TurnStile.PubSub,
                    PubSubTopicsMap.get_topic("STATUS_UPDATE"),
                    %{user_alert_status: updated_user.user_alert_status}
                  )
                  # send reply back to user screen
                  {:ok, system_response_body}

                {:error, error} ->
                  IO.inspect(error, label: "receive_email_alert error in update_user")
                  # update user account as ERROR status
                  case Patients.update_alert_status(
                         current_user,
                         UserAlertStatusTypesMap.get_user_status("ERROR")
                       ) do
                    {:ok, updated_user} ->
                      # IO.inspect(updated_user, label: "updated_user")
                      # send respnse to update UI; match the DB status
                      Phoenix.PubSub.broadcast(
                        TurnStile.PubSub,
                        PubSubTopicsMap.get_topic("STATUS_UPDATE"),
                        %{user_alert_status: updated_user.user_alert_status}
                      )

                    # update user account error failure
                    {:error, error} ->
                      IO.inspect(error, label: "Attempt to update acount as ERROR failed.")
                      # TODO  - send flash to employee
                  end

                  # send reply back to user screen
                  {:error,
                   "An error occurred updating your account. Your account was not updated. Please try again."}
              end

            # alert update failure
            {:error, error} ->
              IO.inspect(error, label: "receive_sms_alert error in update_alert")
              # update user account as ERROR status
              case Patients.update_alert_status(
                     current_user,
                     UserAlertStatusTypesMap.get_user_status("ERROR")
                   ) do
                {:ok, updated_user} ->
                  # IO.inspect(updated_user, label: "updated_user")
                  # send respnse to update UI, match DB
                  Phoenix.PubSub.broadcast(
                    TurnStile.PubSub,
                    PubSubTopicsMap.get_topic("STATUS_UPDATE"),
                    %{user_alert_status: updated_user.user_alert_status}
                  )

                # udate user account error failure
                {:error, error} ->
                  IO.inspect(error, label: "Attempt to update acount as ERROR failed.")
                  # TODO  - send flash to employee
              end
          end
      end
    else
      IO.puts("Error: is_response_valid? returned false in receive_email_alert")

      {:error,
       "Error: your response was invalid or caused system. Your account was not updated. Please try again."}
    end
  end

  def receive_sms_alert(conn, twilio_params) do
    # IO.inspect(twilio_params, label: "twilio_params")
    # get response from text message
    response_body = twilio_params["Body"]
    # invalid incoming user sms
    if is_response_valid?(response_body, AlertFormatTypesMap.get_alert("SMS")) do
      case match_recieved_sms_to_user(twilio_params) do
        {:ok, user} ->
          # IO.inspect(user, label: "USER")
          case AlertUtils.save_received_SMS_alert(user, twilio_params) do
            {:ok, alert} ->
              # IO.inspect(alert, label: "alert")
              # exract response text
              system_response_body = compute_return_body(twilio_params["Body"], AlertFormatTypesMap.get_alert("SMS"))
              # build response map
              system_response_map =
                Alerts.build_system_response_map(alert, body: system_response_body)

              # update alert w system_response map; recieved alerts only
              case Alerts.update_alert(alert, system_response_map) do
                {:ok, _updated_alert} ->
                  # IO.inspect(updated_alert, label: "updated_alert")

                  user_alert_status = compute_user_alert_status(twilio_params["Body"])
                  # update user account in DB
                  case Patients.update_alert_status(user, user_alert_status) do
                    {:ok, updated_user} ->
                      # IO.inspect(updated_user, label: "updated_user")
                      # send valid respnse to update UI - changes status on the page to match
                      Phoenix.PubSub.broadcast(
                        TurnStile.PubSub,
                        PubSubTopicsMap.get_topic("STATUS_UPDATE"),
                        %{user_alert_status: updated_user.user_alert_status}
                      )

                      # physically send valid SMS response
                      send_computed_SMS_system_response(conn, twilio_params)

                    {:error, error} ->
                      IO.inspect(error, label: "receive_sms_alert error in update_user")
                      # update user account as ERROR status
                      case Patients.update_alert_status(
                             user,
                             UserAlertStatusTypesMap.get_user_status("ERROR")
                           ) do
                        {:ok, updated_user} ->
                          # IO.inspect(updated_user, label: "updated_user")
                          # send respnse to update UI; match the DB status
                          Phoenix.PubSub.broadcast(
                            TurnStile.PubSub,
                            PubSubTopicsMap.get_topic("STATUS_UPDATE"),
                            %{user_alert_status: updated_user.user_alert_status}
                          )

                        # udate user account error failure
                        {:error, error} ->
                          IO.inspect(error, label: "Attempt to update acount as ERROR failed.")
                          # TODO  - send flash to employee
                      end

                      # send manual sms system resonse to use
                      send_manual_system_response(
                        conn,
                        "An internal system error occured during account update. Account was not updated."
                      )
                  end

                # alert update failure
                {:error, error} ->
                  IO.inspect(error, label: "receive_sms_alert error in update_alert")
                  # update user account as ERROR status
                  case Patients.update_alert_status(
                         user,
                         UserAlertStatusTypesMap.get_user_status("ERROR")
                       ) do
                    {:ok, updated_user} ->
                      # IO.inspect(updated_user, label: "updated_user")
                      # send respnse to update UI, match DB
                      Phoenix.PubSub.broadcast(
                        TurnStile.PubSub,
                        PubSubTopicsMap.get_topic("STATUS_UPDATE"),
                        %{user_alert_status: updated_user.user_alert_status}
                      )

                    # udate user account error failure
                    {:error, error} ->
                      IO.inspect(error, label: "Attempt to update acount as ERROR failed.")
                      # TODO  - send flash to employee
                  end

                  # send manual sms system resonse to user
                  send_manual_system_response(
                    conn,
                    "An account update error occurred. Account not updated."
                  )
              end

            # alert save failure
            {:error, error} ->
              IO.inspect(error, label: "receive_sms_alert error in save_received_SMS_alert")
              # update user account as ERROR status in DB
              case Patients.update_alert_status(
                     user,
                     UserAlertStatusTypesMap.get_user_status("ERROR")
                   ) do
                {:ok, updated_user} ->
                  # IO.inspect(updated_user, label: "updated_user")
                  # send respnse to update UI, match DB
                  Phoenix.PubSub.broadcast(
                    TurnStile.PubSub,
                    PubSubTopicsMap.get_topic("STATUS_UPDATE"),
                    %{user_alert_status: updated_user.user_alert_status}
                  )

                # udate user account error failure
                {:error, error} ->
                  IO.inspect(error, label: "Attempt to update acount as ERROR failed.")
              end

              send_manual_system_response(
                conn,
                "An internal system error occured during message save. Sorry, your message was not processesed."
              )
          end

        # match failure
        {:error, error} ->
          IO.inspect(error, label: "ERROR")
          # TODO send popup modal to get employee to resolve

          send_manual_system_response(conn, "Error: User account not found.")
      end
    else
      # Invalid response user response; send notification; msg is set in json
      send_computed_SMS_system_response(conn, twilio_params)
    end
  end

  # twlilio webhook in resonse to user reply
  def send_computed_SMS_system_response(conn, twilio_params) do
    IO.puts("SENDING REPLY")

    conn
    |> put_resp_content_type("text/xml")
    # |> maybe_write_alert_cookie(token)
    |> text(IsolatedTwinML.render_response(compute_return_body(twilio_params["Body"], AlertFormatTypesMap.get_alert("SMS"))))
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
  -TODO: if multiple active users active now, and no solution, reqiuire employee action to resolve
  """
  def match_recieved_sms_to_user(twilio_params) do
    # remove starting "+"
    number = Utils.remove_first_string_char(twilio_params["From"], "+")

    # IO.inspect(number, label: "number")
    users_w_number = Patients.get_users_by_phone(number)
    IO.inspect(users_w_number, label: "users_w_number")

    cond do
      # if more than one use w that number
      list_is_greater_than_1(users_w_number) ->
        # check if active
        active_pending_users = Utils.filter_maps_list_by_truthy(users_w_number, "is_active?")
        # TODO - reenage this
        # check if pending - since this is a response
        # |> Utils.filter_maps_list_by_value(:user_alert_status, "pending")

        case list_is_greater_than_1(active_pending_users) do
          true ->
            # require staff action here
            {:error, "User lookup failed. Multiple active users found."}

          false ->
            # return only user
            {:ok, hd(active_pending_users)}
        end

      length(users_w_number) === 1 ->
        {:ok, hd(users_w_number)}

      true ->
        error = "Error: a problem occured looking up matching user"
        {:error, error}
    end
  end

  # check user resonse within text message; find appropriate response to send
  def compute_return_body(response_value, alert_format) do
    # IO.inspect(response_value, label: "response_value")
    #  key into dict to get a match
    if @json["match_incoming_request"][alert_format][response_value] do
      # send the match as reponse
      @json["match_incoming_request"][alert_format][response_value]
    else
      # send a non-matched response
      @json["alerts"]["response"][alert_format]["wrong_response"]
    end
  end

  def compute_user_alert_status(response_value) do
    # body = twilio_params["Body"]

    case response_value do
      "1" ->
        UserAlertStatusTypesMap.get_user_status("CONFIRMED")

      "2" ->
        UserAlertStatusTypesMap.get_user_status("CANCELLED")

      _ ->
        IO.puts(
          "ERROR: invalid response in compute_user_alert_status. This should not occur: validity already checked. Check inputs"
        )

        'INVALID_RESPONSE'
    end
  end

  def is_response_valid?(response_value, alert_format) do
    if is_nil(response_value) do
      false
    else
      #  check if match is valid or not
      if @json["match_incoming_request"][alert_format][response_value], do: true, else: false
    end
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
