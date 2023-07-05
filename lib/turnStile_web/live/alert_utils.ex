defmodule TurnStileWeb.AlertUtils do
  use TurnStileWeb, :live_component
  alias TurnStile.Alerts

  def save_alert(socket, changeset, params \\ %{}) do
    current_employee = Kernel.get_in(socket.assigns, [:current_employee])
    user = Kernel.get_in(socket.assigns, [:user])
    IO.inspect(changeset, label: "changeset in save_alert")
    if !current_employee || !user do
      IO.puts('INNMMMMMMMMMM')
      {:noreply,
      socket
      |> assign(:action, "insert")
      |> put_flash(:error, "Error: Data loss occured on form submission. Please try again.")
      |> push_redirect(to: socket.assigns.return_to)}
    else
      role =
        TurnStile.Roles.get_role(
          current_employee.id,
          current_employee.current_organization_login_id
        )
      # builds an alert changeset with all associations
      case Alerts.create_alert_w_put_assoc(current_employee, user, role, changeset: changeset, alert_attrs: params) do
        {:ok, alert_changeset} ->
          IO.inspect(alert_changeset, label: "alert_changeset")
          # insert alert into DB
          case Alerts.insert_alert(alert_changeset) do
            {:ok, alert} ->
              IO.inspect(alert, label: "alert")
              {:noreply,
              socket
                |> assign(:action, "insert")
                |> put_flash(:success, "Alert created successfully")
              # |> push_redirect(to: socket.assigns.return_to)
            }
            {:error, %Ecto.Changeset{} = changeset} ->
              {:noreply,
            socket
              |> assign(:changeset, changeset)
              |> put_flash(:error, "Alert Not created successfully")}
          end
          # IO.inspect(alert_changeset, label: "alert_changeset")
          # {:noreply,
          # socket
          #   |> put_flash(:success, "Alert created successfully")
          # |> push_redirect(to: socket.assigns.return_to)}
        {:error, error} ->
          IO.puts("ERROR: #{error}")
          {:noreply,
        socket
          |> put_flash(:error, "Alert Not created successfully")}

      end
    end
  end

  def send_alert(socket, %{"employee_id" => employee_id, "user_id" => user_id}) do
    case AlertController.send_twilio_msg(%{"employee_id" => employee_id, "user_id" => user_id}) do
      {:ok, _twl_msg} ->
        socket =
          socket
          |> put_flash(:info, "Alert sent successfully.")
        socket
      # handle twilio errors
      {:error, error_map, _error_code} ->
        socket =
          socket
          |> put_flash(:error, "Alert Failed: #{error_map["message"]}")

        socket

      _ ->
        socket =
          socket
          |> put_flash(:error, "An unknown error occured")

        socket
    end
  end
  #  create and send the alert only
  def send_twilio_msg(%{"employee_id" => _employee_id, "user_id" => _user_id}) do
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
      true ->
        "An unknown error occured"
    end
  end

end
