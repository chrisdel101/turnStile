defmodule TurnStileWeb.AlertUtils do
  use TurnStileWeb, :live_component
  alias TurnStile.Alerts
  @json TurnStile.Utils.read_json("sms.json")

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
      role =
        TurnStile.Roles.get_role(
          current_employee.id,
          current_employee.current_organization_login_id
        )

      # builds an alert changeset with all associations
      case Alerts.create_alert_w_put_assoc(current_employee, user, role,
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
    end
  end

  #  create and send the alert only
  def send_alert(alert) do
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
