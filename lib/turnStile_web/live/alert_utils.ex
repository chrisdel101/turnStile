defmodule TurnStileWeb.AlertUtils do
  use TurnStileWeb, :live_component
  alias TurnStile.Alerts
  alias TurnStile.Staff
  @json TurnStile.Utils.read_json("sms.json")
  alias TurnStileWeb.EmployeeAuth

  @doc """
  handle_save_alert
  -take user params from form and save alert to DB
  """
  def handle_save_alert(socket, changeset, params \\ %{}) do
    current_employee = Kernel.get_in(socket.assigns, [:current_employee])
    user = Kernel.get_in(socket.assigns, [:user])
    IO.inspect(changeset, label: "changeset in handle_save_alert")

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
                      IO.inspect(alert_changeset, label: "alert_changeset")
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

  # sends SMS via twilio
  def send_SMS_alert(alert) do
    if System.get_env("TWILIO_MODE") === "test" do
      case ExTwilio.Message.create(
             to: System.get_env("TEST_NUMBER"),
             from: System.get_env("TWILIO_PHONE_NUM"),
             body: @json["alerts"]["request"]["initial"]
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
