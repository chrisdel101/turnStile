defmodule TurnStileWeb.AlertDisplayLive.PanelComponent do
  use TurnStileWeb, :live_component
  alias TurnStile.Alerts
  alias TurnStile.Alerts.Alert

  @impl true
  def update(props, socket) do
    # IO.inspect(props, label: "props")
    # IO.inspect(socket, label: "socket")

    %{id: user_id, current_employee: current_employee, user: user} = props

    alerts = Alerts.get_alerts_for_user(user_id)
    # IO.inspect(alerts, label: "alerts")
    # build SMS alert as default
    sms_attrs =
      Alerts.build_alert_attrs(
        user,
        AlertCategoryTypesMap.get_alert("CUSTOM"),
        AlertFormatTypesMap.get_alert("SMS")
      )
    changeset = Alerts.create_new_alert(%Alert{}, sms_attrs)

    {:ok,
     socket
     |> assign(props)
     |> assign(:alerts, alerts)
     |> assign(:title, set_title(props.panel))
     |> assign(:page_title, "Alert Panel")
     |> assign(:changeset, changeset)}
  end

  @impl true
  # def handle_event(any, any2, socket) do
  #   IO.inspect(any, label: "any")
  #   IO.inspect(any2, label: "any2")
  #   IO.inspect(socket, label: "socket")
  #   {:noreply, socket}
  # end

  def handle_event("validate", params, socket) do
    # IO.inspect("validate", label: "validate")
    # IO.inspect(socket, label: "params")
    alert_params = Map.get(params, :alert) || Map.get(params, "alert")

    # check for change on radio buttons
    if alert_params && Map.has_key?(socket.assigns.changeset, :data) do
      # IO.inspect(alert_params["alert_format"], label: "alert_params")
      # check which type of alert to change
      cond do
        alert_params["alert_format"] === AlertFormatTypesMap.get_alert("EMAIL") ->
          IO.inspect("EMAIL", label: "EMAIL")

          email_attrs =
            Alerts.build_alert_attrs(
              socket.assigns.user,
              AlertCategoryTypesMap.get_alert("CUSTOM"),
              AlertFormatTypesMap.get_alert("EMAIL")
            )

          changeset =
            socket.assigns.changeset.data
            |> Alerts.change_alert(email_attrs)
            |> Map.put(:action, :validate)

          IO.inspect(changeset, label: "changeset HERE")

          {:noreply, assign(socket, :changeset, changeset)}

        # end
        alert_params["alert_format"] === AlertFormatTypesMap.get_alert("SMS") ->
          IO.inspect("SMS", label: "SMS")

          sms_attrs =
            Alerts.build_alert_attrs(
              socket.assigns.user,
              AlertCategoryTypesMap.get_alert("CUSTOM"),
              AlertFormatTypesMap.get_alert("SMS")
            )

          changeset =
            socket.assigns.changeset.data
            |> Alerts.change_alert(sms_attrs)
            |> Map.put(:action, :validate)

          IO.inspect(changeset, label: "changeset")

          {:noreply, assign(socket, :changeset, changeset)}

        #  end
        true ->
          {:noreply, socket}
      end

      # else
      #   {:noreply, socket}
    end

    # IO.inspect(socket, label: "socket")
  end

  # displays the custom alert form
  def handle_event("dispatch", params, socket) do
    # IO.inspect(params, label: "params")
    changeset = %Alert{}
    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"alert" => alert_params}, socket) do
    # IO.inspect(alert_params, label: "alert_params")
    save_alert(socket, alert_params)
  end

  # defp save_alert(socket, :edit, alert_params) do
  #   case Alerts.update_alert(socket.assigns.alert, alert_params) do
  #     {:ok, _alert} ->
  #       {:noreply,
  #        socket
  #        |> put_flash(:info, "Alert updated successfully")
  #        |> push_redirect(to: socket.assigns.return_to)}

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       {:noreply, assign(socket, :changeset, changeset)}
  #   end
  # end

  defp save_alert(socket, alert_params) do
    current_employee = Kernel.get_in(socket.assigns, [:current_employee])
    user = Kernel.get_in(socket.assigns, [:user])
    IO.inspect(socket, label: "current_employee")

    if !current_employee || !user do
      IO.puts('INNMMMMMMMMMM')
      {:noreply,
      socket
      |> put_flash(:error, "Error: Data loss occured on form submission. Please try again.")
      |> push_redirect(to: socket.assigns.return_to)}
    else

      IO.inspect(socket.assigns.changeset, label: "changeset")

      role =
        TurnStile.Roles.get_role(
          current_employee.id,
          current_employee.current_organization_login_id
        )

      #   # IO.inspect(user, label: "user")
      case Alerts.create_alert_w_assoc(current_employee, user, alert_params, role) do
        {:ok, alert_struct} ->
          IO.inspect(alert_struct, label: "alert_struct")
        {:noreply,
         socket
           |> put_flash(:info, "Alert created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      end
    end
  end

  defp set_title(panel_prop) do
    if panel_prop === "history" do
      "Alert History"
    else
      "Alert Dispatch"
    end
  end
end
