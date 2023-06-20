defmodule TurnStileWeb.AlertDisplayLive.PanelComponent do
  use TurnStileWeb, :live_component

  alias TurnStile.Alerts
  alias TurnStile.Alerts.Alert

  @impl true
  def update(props, socket) do
    IO.inspect(props, label: "props")
    # IO.inspect(socket, label: "socket")

    %{id: user_id, current_employee: current_employee, user: user} = props
    alerts = Alerts.get_alerts_for_user(user_id)
    # IO.inspect(alerts, label: "alerts")
    # build alert to track changes across form
    attrs =
      Alerts.build_alert_attrs(
        user,
        AlertCategoryTypesMap.get_alert("CUSTOM"),
        AlertFormatTypesMap.get_alert("SMS")
      )

    # IO.inspect(changeset.data, label: "HELLO")
    changeset = Alerts.create_alert_w_assoc(current_employee.id, user_id, attrs)

    IO.inspect(changeset  , label: "HELLO")

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
    # IO.inspect(socket, label: "socket")
    alert_params = Map.get(params, :alert) || Map.get(params, "alert")

    # check for change on radio buttons
    if alert_params && Map.has_key?(socket.assigns.changeset, :data) do
      # IO.inspect(alert_params, label: "alert_params")

      changeset =
        socket.assigns.changeset.data
        |> Alerts.change_alert(alert_params)
        |> Map.put(:action, :validate)

      # IO.inspect(socket, label: "changeset")
      {:noreply, assign(socket, :changeset, changeset)}
    else
      {:noreply, socket}
    end

    # IO.inspect(socket, label: "socket")

    # {:noreply, socket}
  end

  def handle_event("dispatch", params, socket) do
    IO.inspect(params, label: "params")
    changeset = %Alert{}
    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"alert" => alert_params}, socket) do
    save_alert(socket, socket.assigns.action, alert_params)
  end

  defp save_alert(socket, :edit, alert_params) do
    case Alerts.update_alert(socket.assigns.alert, alert_params) do
      {:ok, _alert} ->
        {:noreply,
         socket
         |> put_flash(:info, "Alert updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp set_title(panel_prop) do
    if panel_prop === "history" do
      "Alert History"
    else
      "Alert Dispatch"
    end
  end

  defp save_alert(socket, :new, alert_params) do
    case Alerts.create_alert(alert_params) do
      {:ok, _alert} ->
        {:noreply,
         socket
         |> put_flash(:info, "Alert created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
