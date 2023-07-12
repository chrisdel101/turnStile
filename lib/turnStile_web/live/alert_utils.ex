defmodule TurnStileWeb.AlertUtils do
  use TurnStileWeb, :live_component
  alias TurnStile.Alerts.Alert
  alias TurnStile.Alerts
  alias TurnStile.Staff
  @json TurnStile.Utils.read_json("sms.json")
  alias TurnStileWeb.EmployeeAuth
  alias TurnStile.Patients.UserNotifier

  @doc """
  handle_send_alert_save
  -take user params from form and save alert to DB
  -arity/3 handles saving sent alerts
  """
  def handle_send_alert_save(socket, changeset, params \\ %{}) do
    current_employee = Kernel.get_in(socket.assigns, [:current_employee])
    user = Kernel.get_in(socket.assigns, [:user])
    # IO.inspect(changeset, label: "changeset in handle_send_alert_save")

    if !current_employee || !user do
      {:error, "Error: Data loss occured on form submission. Please try again."}
    else
      # check employee/organization roles match
      case Staff.check_employee_has_organization_role(current_employee) do
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
              case TurnStile.Patients.check_user_has_organization(
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

  def handle_recieve_alert_save(user, twilio_params) do
    cond do
      !user ->
        {:error, "Error: Missing user input for handle_recieve_alert_save. Alert not processed."}

      !user.employee ->
        {:error,
         "Error: User input is missing employee in handle_recieve_alert_save. Check preload is run. Alert not processed."}

      true ->
        # employee should be preloaded
        current_employee = user.employee
        # undo captialization of twilio params
        lower_twilio_params =
          Map.new(twilio_params, fn {key, value} -> {String.downcase(key), value} end)

        alert_category = compute_recieved_sms_alert_category(twilio_params)
        attrs = Alerts.build_alert_attrs(user, alert_category, AlertFormatTypesMap.get_alert("SMS"))


        changeset =
          %Alert{}
          |> Alerts.create_new_alert(lower_twilio_params)

        IO.inspect(changeset, label: "changeset in handle_send_alert_save")

        # preloaded employee alredy associated with organization

        case Alerts.create_alert_w_put_assoc(current_employee, user,
               changeset: changeset,
               alert_attrs: lower_twilio_params
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
    end
  end

  # sends SMS via twilio
  def send_SMS_alert(alert) do
    if System.get_env("TWILIO_ALERT_MODE") === "off" do
      {:ok, "FAKE ALERT. Twilio alert mode is off."}
    else
      if System.get_env("SMS_ALERT_MODE") === "dev" do
        case ExTwilio.Message.create(
               to: System.get_env("TEST_NUMBER"),
               from: System.get_env("TWILIO_PHONE_NUM"),
               body: "#{alert.title} - #{alert.body}" || @json["alerts"]["request"]["initial"]
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

  # sends SMS via twilio
  def send_email_alert(alert) do
    # use default system setting for email
    user = TurnStile.Patients.get_user(alert.user_id)
    # IO.inspect( , label: "alertXXXXXX")

    cond do
      alert.alert_category === AlertCategoryTypesMap.get_alert("CUSTOM") ->
        if System.get_env("EMAIL_ALERT_MODE") === "dev" do
          # make sure alert is set to system TO/FROM settings
          # default :from
          alert = Map.put(alert, :from, System.get_env("SYSTEM_ALERT_FROM_EMAIL"))
          # default :to
          alert = alert.to || Map.put(alert, :to, System.get_env("DEV_EMAIL"))
          IO.inspect(alert, label: "XXXXXXXXXXXXX")

          case UserNotifier.deliver_custom_alert(user, alert, "localhost:4000/test123") do
            {:ok, email} ->
              {:ok, email}

            {:error, error} ->
              {:error, error}
          end
        else
          IO.inspect(alert, label: "YYYYYYYYYYY")
          # get TO/FROM/BODY the input form
          case UserNotifier.deliver_custom_alert(user, alert, "localhost:4000/test123") do
            {:ok, email} ->
              IO.inspect(email, label: "email")
              {:ok, email}

            {:error, error} ->
              {:error, error}
          end
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

  def compute_recieved_sms_alert_category(twilio_params) do
    body = twilio_params["Body"]
    #  check if match is valid or not
    if @json["matching_responses"][body] do
      IO.inspect(@json["matching_responses"][body], label: "matching_responses")
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
end
