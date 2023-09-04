  defmodule TurnStileWeb.AlertPanel do
  @doc"""
  Alert Live Component
  - there is no solo view for this page, it is only a modal
  - this liveView controls all logic for the alert panel modal
  - is opened from inside index liveView
  """
  use TurnStileWeb, :live_component
  alias TurnStile.Alerts
  alias TurnStile.Alerts.Alert
  alias TurnStileWeb.AlertUtils
  alias TurnStileWeb.UserLive.Index
  @json TurnStile.Utils.read_json("alert_text.json")

  @impl true
  def update(props, socket) do

    %{id: user_id, current_employee: _current_employee, user: user} = props

    alerts = Alerts.get_alerts_for_user(user_id)
    # IO.inspect(props, label: "props")
    # build default alert attrs to start, just a starting setting
    sms_attrs =
      Alerts.build_alert_specfic_attrs(
        user,
        AlertCategoryTypesMap.get_alert("CUSTOM"),
        AlertFormatTypesMap.get_alert("SMS"),
        title:  "Recieving TurnStile Alert"
      )

    changeset = Alerts.create_new_alert(%Alert{}, sms_attrs,true)
    # IO.inspect(changeset, label: "changeset in update")
    {:ok,
     socket
     |> assign(props)
     |> assign(:json, @json)
     |> assign(:alerts, alerts)
     |> assign(:title, set_title(props.panel)) # set sub-titles in panels
     |> assign(:page_title, "Alert Panel") # set  main page title
     |> assign(:changeset, changeset)}
  end

  @impl true
  # only fires on change-handles changing the form based on radio button selection
  def handle_event("radio_click", params, socket) do
    # IO.inspect("toggle_alert_form", label: "toggle_alert_form")
    # IO.inspect(params, label: "params")
    alert_params = Map.get(params, :alert) || Map.get(params, "alert")

    # check for changes when radio click
    if alert_params && Map.has_key?(socket.assigns.changeset, :data) do
      # IO.inspect(alert_params, label: "alert_params")
      # check which type of alert to change
      cond do
        # radio - flip to email form
        alert_params["alert_format"] === AlertFormatTypesMap.get_alert("EMAIL") ->

          # IO.inspect(socket.assigns.changeset, label: "click HERE radio")
          email_attrs =
            Alerts.build_alert_specfic_attrs(
              socket.assigns.user,
              AlertCategoryTypesMap.get_alert("CUSTOM"),
              AlertFormatTypesMap.get_alert("EMAIL"),
              from: alert_params["from"],
              to: alert_params["to"],
              title: "#{@json["alerts"]["request"]["email"]["initial"]["title"]}",
              body: "#{@json["alerts"]["request"]["email"]["initial"]["body"]}"

            )
          # sets up changeset for template use
          changeset =
            socket.assigns.changeset.data
            |> Alerts.change_alert(email_attrs, true)

          # IO.inspect(changeset, label: "changeset HERE radio")

          {:noreply, assign(socket, :changeset, changeset)}

        # end
        alert_params["alert_format"] === AlertFormatTypesMap.get_alert("SMS") ->
          # IO.inspect(alert_params, label: "SMS")

          sms_attrs =
            Alerts.build_alert_specfic_attrs(
              socket.assigns.user,
              AlertCategoryTypesMap.get_alert("CUSTOM"),
              AlertFormatTypesMap.get_alert("SMS")
            )

          changeset =
            socket.assigns.changeset.data
            |> Alerts.change_alert(sms_attrs, true)

          # IO.inspect(changeset, label: "changeset in validate")

          {:noreply, assign(socket, :changeset, changeset)}

        #  end
        true ->
          {:noreply, socket}
      end
    end
  end

  # # handle form change events - typing
  def handle_event("form_changes", params, socket) do
    alert_params = Map.get(params, :alert) || Map.get(params, "alert")
    # IO.inspect(socket.assigns.changeset, label: "socket.assigns.changeset")
    cond do
      # flip to email form
      alert_params["alert_format"] === AlertFormatTypesMap.get_alert("EMAIL") ->
        # IO.inspect(socket.assigns.changeset, label: "socket.assigns.changeset IN")
        # manually reassign category
        alert_params = Map.put(alert_params, "alert_category", AlertCategoryTypesMap.get_alert("CUSTOM"))
        # IO.inspect(alert_params, label: "PPP")
        # build new alert that is an email

        # enforce form validations here on email alert
        changeset =
          socket.assigns.changeset.data
          |> Alerts.change_alert(alert_params, true)

        IO.inspect(changeset, label: "changeset HERE2")

        {:noreply, assign(socket, :changeset, changeset)}

      alert_params["alert_format"] === AlertFormatTypesMap.get_alert("SMS") ->
        # IO.inspect(alert_params, label: "SMS")
        # manually reassign category
        alert_params = Map.put(alert_params, "alert_category", AlertCategoryTypesMap.get_alert("CUSTOM"))

        # enforce form validations here on sms alert
        changeset =
          socket.assigns.changeset.data
          |> Alerts.change_alert(alert_params, true)

        # IO.inspect(changeset, label: "changeset in validate")

        {:noreply, assign(socket, :changeset, changeset)}

      true ->
        {:noreply, socket}
    end
  end

  # send alert from custom dispatch form
  def handle_event("send_custom_alert", %{"alert" => alert_params}, socket) do
     # manually add category
      alert_params = Map.put(alert_params, "alert_category", AlertCategoryTypesMap.get_alert("CUSTOM"))
      changeset = Alerts.create_new_alert(%Alert{}, alert_params, true)
      AlertUtils.handle_sending_alert("send_custom_alert",
       changeset, socket)
  end

  defp set_title(panel_prop) do
    if panel_prop === "history" do
      "Alert History"
    else
      "Alert Dispatch"
    end
  end
end
