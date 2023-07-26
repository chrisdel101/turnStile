defmodule TurnStileWeb.AlertUtils do
  use TurnStileWeb, :live_component
  alias TurnStile.Alerts.Alert
  alias TurnStile.Alerts
  alias TurnStile.Staff
  @json TurnStile.Utils.read_json("sms.json")
  alias TurnStileWeb.EmployeeAuth
  alias TurnStile.Patients.UserNotifier

  @doc """
  authenticate_and_save_sent_alert
  -take user params from form and save alert to DB
  -auth emp/org match, emp permissions, user in org
  -assoc alert w all relevant others
  -return saved alert
  -partner function to save_received_alert
  """
  def authenticate_and_save_sent_alert(socket, changeset, params \\ %{}) do
    current_employee = Kernel.get_in(socket.assigns, [:current_employee])
    user = Kernel.get_in(socket.assigns, [:user])
    # IO.inspect(changeset, label: "changeset in authenticate_and_save_sent_alert")

    if !current_employee || !user do
      {:error, "Error: Data loss occured on form submission. Please try again."}
    else
      # check employee/organization roles match
      case Staff.check_employee_matches_organization(current_employee) do
        {:error, error} ->
          IO.puts("ERROR: #{error}")
          {:error, error}

        {:ok, _} ->
          IO.puts("Employee has correct role")
          # check employee has permissions
          case EmployeeAuth.has_alert_send_permissions?(socket, current_employee) do
            true ->
              IO.puts("Employee has correct permissions")
              # check user is part of organization
              case TurnStile.Patients.check_user_assoc_in_organization(
                     user,
                     current_employee.current_organization_login_id
                   ) do
                {:ok, _} ->
                  case Alerts.create_alert_w_put_assoc(current_employee, user,
                         changeset: changeset,
                         alert_attrs: params
                       ) do
                    {:ok, alert_changeset} ->
                      # IO.inspect(alert_changeset, label: "alert_changeset")
                      # insert alert into DB
                      case Alerts.insert_alert(alert_changeset) do
                        {:ok, alert} ->
                          {:ok, alert}

                        {:error, %Ecto.Changeset{} = changeset} ->
                          {:error, changeset}
                      end

                    {:error, error} ->
                      IO.puts("ERROR: #{error}")
                      {:error, error}
                  end

                {:error, error} ->
                  IO.puts("ERROR: #{error}")
                  {:error, error}
              end

            false ->
              IO.puts("Employee does not have correct permissions")
              {:error, "Error: You do not have permission to send alerts."}
          end
      end
    end
  end
    @doc """
  save_received_alert
  -take twilio params as arrow map
  -No auth for incoming alerts needed; match is checked before this call
  -assoc alert w all relevant others
  -return saved alert
  -partner function to authenticate_and_save_sent_alert
  """
  def save_received_alert(user, twilio_params) do
    cond do
      !user ->
        {:error, "Error: Missing user input for save_received_alert. Alert not processed."}

      !user.employee ->
        {:error,
         "Error: User input is missing employee in save_received_alert. Check preload is run. Alert not processed."}

      true ->
        # undo captialization of twilio params
        lower_twilio_params =
          Map.new(twilio_params, fn {key, value} -> {String.downcase(key), value} end)

        alert_category = compute_sms_category_from_body(twilio_params)
        # build attr map
        attrs =
          Alerts.build_alert_attrs(user, alert_category, AlertFormatTypesMap.get_alert("SMS"))

        # merge w twilio params
        twilio_params1 =
          Map.merge(TurnStile.Utils.convert_atom_map_to_arrow(attrs), lower_twilio_params)

        changeset =
          %Alert{}
          |> Alerts.create_new_alert(twilio_params1)

        # IO.inspect(changeset, label: "changeset in authenticate_and_save_sent_alert")

        # employee should be preloaded (last associated employee)
        current_employee = user.employee

        case Alerts.create_alert_w_put_assoc(
               current_employee,
               user,
               changeset: changeset,
               alert_attrs: lower_twilio_params,
               organization_struct: user.organization
             ) do
          {:ok, alert_changeset} ->
            # IO.inspect(alert_changeset, label: "alert_changeset")
            # insert alert into DB
            case Alerts.insert_alert(alert_changeset) do
              {:ok, alert} ->
                # IO.inspect(alert, label: "alert in save_received_alert")
                {:ok, alert}

              {:error, %Ecto.Changeset{} = changeset} ->
                {:error, changeset}
            end

          {:error, error} ->
            IO.puts("ERROR: #{error}")
            {:error, error}
        end
    end
  end

  # sends SMS via twilio; limited to verfied nums w trial account
  def send_SMS_alert(alert) do
    if System.get_env("TWILIO_ALERT_MODE") === "off" do
      {:ok, "FAKE ALERT. Twilio alert mode is off."}
    else
      if System.get_env("SMS_ALERT_MODE") === "dev" do
        case ExTwilio.Message.create(
               to: System.get_env("TEST_NUMBER"),
               from: System.get_env("TWILIO_PHONE_NUM"),
               body:
                 handle_alert_body_and_title_display(alert.title, alert.body) ||
                   @json["alerts"]["request"]["sms"]["initial"]
             ) do
          {:ok, twilio_msg} ->
            {:ok, twilio_msg}

          # handle twilio errors
          {:error, error_map, error_code} ->
            {:error, error_map, error_code}

          _ ->
            {:error, "An unknown error occured"}
        end
      else
        case ExTwilio.Message.create(
               to: alert.to,
               from: alert.from,
               body: alert.body
             ) do
          {:ok, twilio_msg} ->
            # IO.inspect(twilio_msg, label: "send_SMS_alert")
            {:ok, twilio_msg}

          # handle twilio errors
          {:error, error_map, error_code} ->
            {:error, error_map, error_code}

          _ ->
            {:error, "An unknown error occured"}
        end
      end
    end
  end

  # sends email via mailgun; limited to verfied address w trial account
  def send_email_alert(alert) do
    # use default system setting for email
    user = TurnStile.Patients.get_user(alert.user_id)

    alert = maybe_append_development_fields(alert)
    # IO.inspect(alert, label: "EEEEEEalert in send_email_alert")
    cond do
      alert.alert_category === AlertCategoryTypesMap.get_alert("CUSTOM") ->
        # put in build_user_alert_url as a callback
          case TurnStile.Patients.deliver_user_alert_reply_instructions(user, alert, &TurnStile.Utils.build_user_alert_url(&1, &2, &3)) do
            {:ok, email} ->
              {:ok, email}
            {:error, error} ->
              IO.inspect(error, label: "ERROR: in send_email_alert")
              {:error, error}
          end
      # initial alert
      true ->
        case UserNotifier.deliver_initial_alert(user, "localhost:4000/test123") do
          {:ok, email} ->
            {:ok, email}

          {:error, error} ->
            {:error, error}
        end
    end
  end
  # handle fill-in :to, :from when flag
  defp maybe_append_development_fields(alert) do
    if System.get_env("EMAIL_ALERT_MODE") === "dev" do
      # make sure alert is set to system TO/FROM settings
      # default :from
      alert = Map.put(alert, :from, System.get_env("SYSTEM_ALERT_FROM_EMAIL")) |> Map.put(:to, System.get_env("DEV_EMAIL"))
      alert
    else
      alert
    end
  end


  defp compute_sms_category_from_body(twilio_params) do
    body = twilio_params["Body"]
    #  check if match is valid or not
    if @json["matching_responses"][body] do
      # IO.inspect(@json["matching_responses"][body], label: "matching_responses")

      cond do
        body === "1" ->
          AlertCategoryTypesMap.get_alert("CONFIRMATION")

        body === "2" ->
          AlertCategoryTypesMap.get_alert("CANCELLATION")

        true ->
          IO.puts("Error: invalid response in handle_user_account_updates")
          nil
      end
    end
  end

  def handle_updating_user_alert_send_status(user, alert_category, opts \\ []) do
    cond do
      # send intital alert w instructions
      AlertCategoryTypesMap.get_alert("INITIAL") === alert_category ->
        # update user account
        TurnStile.Patients.update_alert_status(
          user,
          UserAlertStatusTypesMap.get_user_status("PENDING")
        )
      AlertCategoryTypesMap.get_alert("CUSTOM") === alert_category ->
        update_status = Keyword.get(opts, :update_status)
        if update_status do
          # set to manual status
          TurnStile.Patients.update_alert_status(
            user,
            UserAlertStatusTypesMap.get_user_status(String.upcase(update_status))
          )
        else
        #  assume inital alert (i.e email) and set to pending
          TurnStile.Patients.update_alert_status(
            user,
            UserAlertStatusTypesMap.get_user_status("PENDING")
          )
        end
      # emails is in this category; takes opts to handle actual custom case else is treated as initial
      AlertCategoryTypesMap.get_alert("CUSTOM") === alert_category ->
        # update user account
        TurnStile.Patients.update_alert_status(
          user,
          UserAlertStatusTypesMap.get_user_status("PENDING")
        )

      true ->
        {:error, "Error: invalid alert_category in handle_updating_user_alert_send_status"}
    end
  end

  defp handle_alert_body_and_title_display(body, title) do
    # performs what original code wanted but didn't work: "#{alert.title} - #{alert.body}
    # code via CHATgpt
    case {title, body} do
      {nil, nil} -> nil
      {nil, _} -> body
      {_, nil} -> nil
      {_, _} -> "#{title} - #{body}"
    end
  end
end
