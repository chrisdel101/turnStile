defmodule TurnStileWeb.UserLive.Index.HandleEvent do
  use Phoenix.Component

  alias TurnStile.Patients
  alias TurnStile.Alerts.Alert
  alias TurnStile.Alerts
  alias TurnStileWeb.AlertUtils
  alias TurnStileWeb.EmployeeAuth

 # called - from popup match review button on-click
 def handle_event("user_alert_match_review", %{"value" => ""}, socket) do

  {:noreply, socket |> push_patch(to: Routes.user_index_path(socket, :display_existing_users, socket.assigns.current_employee.current_organization_login_id, socket.assigns.current_employee.id))}
end

# called - from popup match review button on-click
def handle_event("user_alert_match_reject", _unsigned_params, socket) do

  {:noreply, socket |> push_patch(to: Routes.user_index_path(socket, :display_existing_users, socket.assigns.current_employee.current_organization_login_id, socket.assigns.current_employee.id))}
end

# called - from popup review button on-click
# - extract mesage from list and send to apply_action
def handle_event("user_registration_data_accept", params, socket) do
  # get id from button value field
  message_id = params["value"]
  # match id to msg key id
  message =
    Enum.find(socket.assigns.user_registration_messages, fn msg ->
      (Map.keys(msg) === [message_id]) || (Map.keys(msg) === [String.to_integer(message_id)])
    end)

  # send msg to upsert form
  user_params = Map.values(message)
  {:ok, user_params} = Enum.fetch(user_params, 0)
  IO.inspect(message, label: "user_registration_accept")
  # build new user
  changeset = Patients.create_user(user_params)
  # IO.inspect(changeset, label: "user_registration_accept")
  # apply_action(socket, :insert, %{"user_changeset" => changeset})
  {:noreply,
   socket
   |> assign(:live_action, :insert)
   # apply_action :insert
   |> TurnStileWeb.UserLive.Index.apply_action(:insert, %{"user_changeset" => changeset},
     subtitle:
       "Review user registration information. If correct, click 'Save' to add user to system.",
      page_title: "Add New User Via Incoming User Data")}
end
# called - from popup reject button on-click
# - extract mesage from list and send to apply_action
def handle_event("user_registration_data_reject", params, socket) do
  # get id from button value field
  message_id = params["value"]
  IO.inspect("fired")
  # find msg in list
  message =
    Enum.find(socket.assigns.user_registration_messages, fn msg ->
      (Map.keys(msg) === [message_id]) || (Map.keys(msg) === [String.to_integer(message_id)])
    end)
  # remove message from list - cannot rely on index so must locate full message first
  user_registration_messages =
    List.delete(socket.assigns.user_registration_messages, message)
  # get values from map -returns list
  # user_params = Map.values(message)
  # extract values from list - returns map of user_params
  # {:ok, user_params} = Enum.fetch(user_params, 0)
  # IO.inspect(message, label: "user_registration_accept")
  # build new user
  # changeset = Patients.create_user(user_params)
  # IO.inspect(changeset, label: "user_registration_accept")
  # apply_action(socket, :insert, %{"user_changeset" => changeset})
  {:noreply,
   socket
   |> assign(:user_registration_messages, user_registration_messages)}
   # apply_action :insert
  #  |> apply_action(:insert, %{"user_changeset" => changeset},
  #    subtitle:
  #      "Review user registration information. If correct, click 'Save' to add user to system.",
  #     page_title: "Add New User Via Incoming User Data")}
end

def handle_event(
      "send_initial_alert",
      %{"alert-format" => alert_format, "user-id" => user_id, "value" => _value},
      socket
    ) do
  # assign user to socket to pass along
  socket = assign(socket, :user, Patients.get_user(user_id))
  # error checking conditions
  cond do
    # check user is not nil
    !Map.get(socket.assigns, :user) ->
      {
        :noreply,
        socket
        |> put_flash(
          :error,
          "User not found. Alert not sent. If you are sure this user exists, then a system error has occured."
        )
      }

    # check not missing phone
    alert_format === AlertFormatTypesMap.get_alert("SMS") &&
        !Map.get(socket.assigns.user, :phone) ->
      {
        :noreply,
        socket
        |> put_flash(
          :error,
          "Default alert type is set to SMS but user phone number is missing. Add user phone number to send SMS alert."
        )
      }

    alert_format === AlertFormatTypesMap.get_alert("EMAIL") &&
        !Map.get(socket.assigns.user, :email) ->
      {
        :noreply,
        socket
        |> put_flash(
          :error,
          "Default alert type is set to email but user email is missing. Add user email to send email alert."
        )
      }

    # no validation errors - proceed with sending alert
    true ->
      attrs = Alerts.build_alert_specfic_attrs(
        socket.assigns.user,
        AlertCategoryTypesMap.get_alert("INITIAL"),
        alert_format
      )
      changeset = Alerts.create_new_alert(%Alert{}, attrs)
      AlertUtils.handle_sending_alert("send_initial_alert",
     changeset, socket)
  end
end

def handle_event("delete", %{"id" => id}, socket) do
  current_employee = socket.assigns.current_employee

  if EmployeeAuth.has_user_delete_permissions?(socket, current_employee) do
    user = Patients.get_user(id)
    {:ok, _} = Patients.delete_user(user)

    socket =
      socket
      |> put_flash(:warning, "User deleted successfully.")

    {:noreply,
     assign(
       socket,
       :users,
       Patients.filter_active_users_x_mins_past_last_update(
         current_employee.current_organization_login_id,
         @filter_active_users_mins
       )
     )}
  else
    socket =
      socket
      |> put_flash(:error, "Insuffient permissions to perform user delete")

    {:noreply,
     assign(
       socket,
       :users,
       Patients.filter_active_users_x_mins_past_last_update(
         current_employee.current_organization_login_id,
         @filter_active_users_mins
       )
     )}
  end
end

def handle_event("remove", %{"id" => id}, socket) do
  current_employee = socket.assigns.current_employee

  if EmployeeAuth.has_user_remove_permissions?(socket, current_employee) do
    user = Patients.get_user(id)
    Patients.deactivate_user(user)

    socket =
      socket
      |> put_flash(:info, "User inactivated.")

    {:noreply,
     assign(
       socket,
       :users,
       Patients.filter_active_users_x_mins_past_last_update(
         current_employee.current_organization_login_id,
         @filter_active_users_mins
       )
     )}
  else
    socket =
      socket
      |> put_flash(:error, "Insuffient permissions to perform user remove")

    {:noreply,
     assign(
       socket,
       :users,
       Patients.filter_active_users_x_mins_past_last_update(
         current_employee.current_organization_login_id,
         @filter_active_users_mins
       )
     )}
  end
end
end
