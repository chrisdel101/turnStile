defmodule TurnStileWeb.AlertController do
  use TurnStileWeb, :controller
  alias TurnStile.Utils
  alias TurnStile.Patients
  alias TurnStile.Patients.User
  alias TurnStileWeb.AlertUtils
  alias TurnStile.Alerts
  @json Utils.read_json("alert_text.json")
  import Ecto.Changeset

  def receive_email_alert(conn, %{
        "user_id" => _user_id,
        "response_value" => response_value,
        "response_key" => response_key
      }) do
    current_user = conn.assigns[:current_user]

    # IO.inspect(response_value, label: "response_value")
    user_alert_status = compute_new_user_alert_status(response_value)

    if is_response_valid?(response_value, AlertFormatTypesMap.get_alert("EMAIL")) &&
         alert_has_changes?(current_user, user_alert_status) do
      case AlertUtils.save_received_email_alert(
             current_user,
             %{"response_value" => response_value, "response_key" => response_key}
           ) do
        # insert inside create_alert_w_put_assoc returns changeset
        {:error, %Ecto.Changeset{} = changeset} ->
          {:error, changeset}

        # create_alert_w_put_assoc returns create_alert_w_put_assoc
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
          # alert save failure return
          {:error, error_msg}

        {:ok, alert} ->
          # IO.inspect(alert, label: "receive_email_alert alert saved")
          system_response_body =
            compute_return_body(response_value, AlertFormatTypesMap.get_alert("EMAIL"))

          system_response_map =
            Alerts.build_system_response_map(alert, body: system_response_body)

          # IO.inspect(system_response_map, label: "receive_email_alert sytem_response_map")
          #  alert w system_response map; recieved alerts only
          case Alerts.update_alert(alert, system_response_map) do
            {:ok, updated_alert} ->
              # IO.inspect(updated_alert, label: "receive_email_alert updated_alert w system_response_map")

              # user_alert_status = compute_new_user_alert_status(response_value)
              changeset = change(current_user, %{user_alert_status: user_alert_status})
              # only send change updates if valid
              if changeset.valid? && changeset.changes !== %{} do
                IO.inspect(changeset, label: "changesetXXXX")
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
                    {:ok, updated_alert}

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
      if alert_has_changes?(current_user, user_alert_status) do
        IO.puts("INFO: user send alert mathing there current state. No action taken")
        {:no_action}
      else
        IO.puts("Error: is_response_valid? returned false in receive_email_alert")

        {:error,
         "Error: your response was invalid or caused system. Your account was not updated. Please try again."}
      end
    end
  end

  def receive_sms_alert(conn, twilio_params) do
    # IO.inspect(twilio_params, label: "twilio_params")
    # get response from text message
    response_body = twilio_params["Body"]
    user_alert_status = compute_new_user_alert_status(twilio_params["Body"])
    # invalid incoming user sms
    if is_response_valid?(response_body, AlertFormatTypesMap.get_alert("SMS")) do
      case match_recieved_sms_to_single_user(twilio_params) do
        %User{} = user ->
          # only allow if alert has changse - block repeating same action
          if alert_has_changes?(user, user_alert_status) do
            # set account_counconfirmed on init sms
            Patients.confirm_user_account_via_init_valid_sms(user)
            # alerts making here are ["CONFIRMED", "CANCELLED"]
            with {:ok, alert} <- AlertUtils.save_received_SMS_alert(user, twilio_params) do
              # IO.inspect(user, label: "USER")

              # exract response text
              system_response_body =
                compute_return_body(twilio_params["Body"], AlertFormatTypesMap.get_alert("SMS"))

              # build return response map
              system_response_map =
                Alerts.build_system_response_map(alert, body: system_response_body)

              # update alert obj w system_response map; on recieved alerts only
              case Alerts.update_alert(alert, system_response_map) do
                {:ok, updated_alert} ->
                  IO.inspect(updated_alert, label: "updated_alert")

                  # user_alert_status = compute_new_user_alert_status(twilio_params["Body"])
                  changeset = change(user, %{user_alert_status: user_alert_status})
                  # only send change updates if valid
                  # if changeset.valid? && changeset.changes !== %{} do
                  if changeset.valid? do
                    # update user account in DB
                    case Patients.update_alert_status(user, user_alert_status) do
                      {:ok, updated_user} ->
                        # IO.inspect(updated_user, label: "updated_user")
                        # tell LV to user status
                        Phoenix.PubSub.broadcast(
                          TurnStile.PubSub,
                          PubSubTopicsMap.get_topic("STATUS_UPDATE"),
                          %{user_alert_status: updated_user.user_alert_status}
                        )
                      # update_alert_status error; but update alert was :ok
                      {:error, error} ->
                        # TODO: set an new error type to reload and update only the user status - only error on emplpyee side here
                        IO.inspect(error, label: "Error in update_alert_status")
                        # was setting to error status but this is update failure error

                        # still send user a resoponses as usuual
                        Phoenix.PubSub.broadcast(
                          TurnStile.PubSub,
                          PubSubTopicsMap.get_topic("STATUS_UPDATE"),
                          %{user_alert_status: user.user_alert_status}
                        )
                    end
                    # send response no matter status update error
                    send_computed_SMS_system_response(conn, twilio_params)
                    # if changeset.valid? fails; send blank response
                  else
                    conn
                    |> resp(202, "Accepted: no action")
                    |> send_resp()
                  end

                # update_alert in DB failure - change to error status
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

                    # update user account failure
                    {:error, error} ->
                      # TODO: (like prev) set an new error type to reload and update only the user status - only error on emplpyee side here
                      IO.inspect(error, label: "Attempt to update acount as ERROR failed.")
                      # TODO  - send flash to employee or retry
                  end

                  # send manual sms system resonse to user
                  send_manual_system_response(
                    conn,
                    "An account update error occurred. Account not updated."
                  )
              end

              # alert save failure
            else
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
                    # TODO: (like prev) set an new error type to reload and update only the user status - only error on emplpyee side here
                    IO.inspect(error, label: "Attempt to update acount as ERROR failed.")
                end

                send_manual_system_response(
                  conn,
                  "An internal system error occured during message save. Sorry, your message was not processesed."
                )
            end

            # alert_has_changes? is false
          else
            IO.puts("INFO: user send alert mathing there current state. No action taken")

            conn
            |> send_resp(202, "Accepted: no action")
          end


        # no matches found
        nil ->
          IO.puts("Alert info: no match of match state params failed")
          # TODO send popup modal to get employee to resolve

          send_manual_system_response(conn, "Error: User account not found.")
      end
    else
      # Invalid response user response; send notification; msg is set in json
      send_computed_SMS_system_response(conn, twilio_params)
    end
  end
  @doc """
  match_user_with_correct_state
  -checks incoming state against current user state
  # -if the user state is the correct one: if SMS follows the users, that then we knnow this must be the matching user
  - return tuple with state
  """
  def match_user_with_correct_state(user, new_alert_status) do
    cond do
      # update pending -> conf/ cancel
      user.user_alert_status === UserAlertStatusTypesMap.get_user_status("PENDING") &&
          (new_alert_status === UserAlertStatusTypesMap.get_user_status("CONFIRMED") ||
             new_alert_status === UserAlertStatusTypesMap.get_user_status("CANCELLED")) ->
        {:ok, user}

      # update error ->  conf/ cancel
      user.user_alert_status == UserAlertStatusTypesMap.get_user_status("ERROR") &&
          (new_alert_status === UserAlertStatusTypesMap.get_user_status("CONFIRMED") ||
             new_alert_status === UserAlertStatusTypesMap.get_user_status("CANCELLED")) ->
        {:ok, user}

      # update conf -> cancel
      user.user_alert_status == UserAlertStatusTypesMap.get_user_status("CONFIRMED") &&
          new_alert_status == UserAlertStatusTypesMap.get_user_status("CANCELLED") ->
        {:ok, user}

      # cannot update when cancelled
      user.user_alert_status == UserAlertStatusTypesMap.get_user_status("CANCELLED") ->
        {:cancelled, nil}

      #  cannot update when expired
      user.user_alert_status == UserAlertStatusTypesMap.get_user_status("EXPIRED") ->
        {:expired, nil}

      # cannot update when still in init state
      user.user_alert_status == UserAlertStatusTypesMap.get_user_status("UNALERTED") ->
        {:unalerted, nil}

      # no other changes allowed
      true ->
        IO.puts(
          "match_user_with_correct_state: misc user state does not match any state conditions"
        )

        {:not_found, nil}
    end
  end

  # if user state is diff that current is true
  defp alert_has_changes?(user, new_alert_status) do
    IO.inspect(user, label: "user.user_alert_status")
    IO.inspect(new_alert_status, label: "new_alert_status")
    user.user_alert_status !== new_alert_status
  end

  # twlilio webhook in resonse to user reply
  defp send_computed_SMS_system_response(conn, twilio_params) do
    conn
    |> put_resp_content_type("text/xml")
    # |> maybe_write_alert_cookie(token)
    |> text(
      IsolatedTwinML.render_response(
        compute_return_body(twilio_params["Body"], AlertFormatTypesMap.get_alert("SMS"))
      )
    )
  end

  # twlilio webhook in resonse to user reply
  defp send_manual_system_response(conn, response_body) do
    conn
    |> put_resp_content_type("text/xml")
    # |> maybe_write_alert_cookie(token)
    |> text(IsolatedTwinML.render_response(response_body))
  end

  # defp match_recieved_sms_to_user(twilio_params) do
  #   active_users =  match_recieved_sms_to_single_user(twilio_params)
  #   cond do
  #     Utils.is_list_greater_that_1?(active_users) ->

  #       new_alert_status = compute_new_user_alert_status(twilio_params["Body"])
  #       match_user_with_correct_state(user, new_alert_status)
  #       else
  #         IO.puts("match_recieved_sms_to_user: single user match is not active")
  #         nil
  #     # if is just a single user
  #     !is_nil(users_match_phone) && length(users_match_phone) === 1 ->
  #       active_users = Utils.filter_maps_list_by_truthy(users_match_phone, "is_active?")
  #       {:single_match, active_users}

  #     #  if there are zero or nil matches
  #     true ->
  #       {:not_found, []}
  #   end
  #   #   {:single_match, users} ->
  #   #     # is user active, what is there state
  #   #     [user] = users
  #   #     if user.is_active? do
  #   #       new_alert_status = compute_new_user_alert_status(twilio_params["Body"])
  #   #       match_user_with_correct_state(user, new_alert_status)
  #   #     else
  #   #       IO.puts("match_recieved_sms_to_user: single user match is not active")
  #   #       nil
  #   #     end
  #   #   {:multiple_matches, active_users}->

  #   #   {:not_found, []}

  #   # end
  # end

  # match_recieved_sms_to_single_user
  # -handles incoming SMS messages from Twilio-
  # -only available useful param is phone number
  # -narrows down to most likey single user that matches
  # -returns user struct or nil

  def match_recieved_sms_to_single_user(nil), do: nil
  def match_recieved_sms_to_single_user(twilio_params) do
    # remove starting "+"
    number = Utils.remove_first_string_char(twilio_params["From"], "+")

    # IO.inspect(number, label: "number")
    users_match_phone = Patients.get_all_users_by_phone(number)
    # IO.inspect(users_match_phone, label: "users_match_phone")
    # filter for active users only
    active_matching_users = Utils.filter_maps_list_by_truthy(users_match_phone, "is_active?")
    # IO.inspect(active_matching_users, label: "active_matching_users")

    cond do
      # if multiple active user with phone num
      Utils.is_list_greater_that_1?(active_matching_users) ->
        # check alert formats set to SMS
        users_in_SMS_mode =
          Enum.filter(active_matching_users, fn user ->
            user.alert_format_set === AlertFormatTypesMap.get_alert("SMS")
          end)

        cond do
          # if mutiple with SMS mode - business logic should block mutiple users with SMS mode from being active
          Utils.is_list_greater_that_1?(users_in_SMS_mode) ->
            new_alert_status = compute_new_user_alert_status(twilio_params["Body"])
            # filter out users with correct matching state
            actives_stateful_users =
              Enum.filter(users_in_SMS_mode, fn user ->
                match_user_with_correct_state(user, new_alert_status) ===
                  {:ok, %TurnStile.Patients.User{} = user}
              end)

            cond do
              # multple active, SMS mode, w correct state - this should never happen
              Utils.is_list_greater_that_1?(actives_stateful_users) ->
                IO.puts(
                  "match_recieved_sms_to_single_user: No matching users_in_SMS_mode found.")
                nil
              # out of matches single is: active, SMS mode, w correct state
             length(actives_stateful_users) === 1 ->
                # this should not happen either
                hd(actives_stateful_users)
              true ->
                IO.puts(
                  "match_recieved_sms_to_single_user: No matching actives_stateful_users found")
                nil
            end
          length(users_in_SMS_mode) === 1 ->
            hd(users_in_SMS_mode)

          true ->
            IO.puts(
              "match_recieved_sms_to_single_user: zero users_in_SMS_mode found")
            nil
        end

      # should go here: if only single active user with phone num
      !is_nil(active_matching_users) && length(active_matching_users) === 1 ->
        new_alert_status = compute_new_user_alert_status(twilio_params["Body"])
        # extract single user
        [user] = active_matching_users
        # returns a user or nil
        with {:ok, user} <- match_user_with_correct_state(user, new_alert_status) do
          user
        else
          # failed state case
          # print so can see reason for no nil return
          {action, nil} ->
            IO.inspect(action,
              label: "match_recieved_sms_to_single_user: user state does not match action"
            )

            nil
        end
      #  if there are zero or nil matches
      true ->
        IO.puts("match_recieved_sms_to_single_user: No matching users found.")
        nil
    end
  end

  # check user resonse within text message; find appropriate response to send
  defp compute_return_body(response_value, alert_format) do
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

  def compute_new_user_alert_status(response_value) do
    # body = twilio_params["Body"]

    case response_value do
      "1" ->
        UserAlertStatusTypesMap.get_user_status("CONFIRMED")

      "2" ->
        UserAlertStatusTypesMap.get_user_status("CANCELLED")

      _ ->
        IO.puts(
          "ERROR: invalid response in compute_new_user_alert_status. This should not occur: validity already checked. Check inputs"
        )

        ~c"INVALID_RESPONSE"
    end
  end

  defp is_response_valid?(response_value, alert_format) do
    IO.inspect(response_value, label: "is_response_valid")

    if is_nil(response_value) do
      false
    else
      #  check if match is valid or not
      if @json["match_incoming_request"][alert_format][response_value], do: true, else: false
    end
  end

  # def is_liveView_connected({:isconnected}, socket)
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
