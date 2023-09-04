defmodule TurnStileWeb.UserLive.UpsertFormComponent do
  # handles the logic for the modals
  use TurnStileWeb, :live_component
  import Ecto.Changeset
  alias TurnStileWeb.EmployeeAuth
  alias TurnStile.Patients
  alias TurnStile.Patients.User
  alias TurnStileWeb.UserLive.Index.IndexUtils


  @impl true
  # empty user struct getting passed as props; see index apply_action(:new)
  # - search insert passes user struct
  # - dispay insert passes a user changeset
  def update(%{user: user, live_action: live_action, user_changeset: user_changeset} = props, socket) do
    # IO.inspect(props, label: "props")
    # IO.inspect(action)
    user =
      case user do
        # :insert: from search: it's a formed user struct then fill in the form
        %User{} ->
          user

        # :new: if user is empty map it's a blank user form
        %{} ->
          %User{}

        # if form is opened out of sequence, stop error by setting user to
        nil ->
          %User{}
      end

    # IO.inspect(action)

    # build default user changeset
    changeset = if !is_nil(user_changeset), do: user_changeset, else: Patients.change_user(user)
    # IO.inspect(changeset, label: "changeset upsert")

    disable_input = if live_action && live_action === :select, do: true, else: false

    disabled_hover_info =
      if disable_input === true, do: "Form is readonly. To edit, go back.", else: nil

    {:ok,
     socket
     |> assign(props)
     |> maybe_assign_code(nil)
     #  disable form on :select - make readonly
     |> assign(:disable_input, disable_input)
     #  add 'title' attr for user info purposes
     |> assign(:disabled_hover_info, disabled_hover_info)
     # assign user struct so 'validate' works
     |> assign(:user, apply_changes(changeset))
     |> assign(:live_action, live_action)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    # IO.inspect(socket.assigns.user, label: "user_params")
    changeset =
      socket.assigns.user
      |> Patients.change_user(user_params)
      |> Map.put(:action, :validate)

    # IO.inspect(changeset, label: "VALIDATE")
    {:noreply, assign(socket, :changeset, changeset)}
  end

  # only fires on change- handles changing the form based on radio button selection
  def handle_event("radio_click", %{"user" => %{"alert_format_set" => alert_format}}, socket) do
    # IO.inspect(socket.assigns.changeset, label: "radio_click")
    # IO.inspect(alert_format, label: "radio_click")

    # # check for changes when radio click
    if alert_format && Map.has_key?(socket.assigns.changeset, :data) do
      # check which type of alert to change
      cond do
        # radio - flip to email form
        alert_format === AlertFormatTypesMap.get_alert("EMAIL") ->
          # sets up changeset for template use
          changeset =
            Ecto.Changeset.change(socket.assigns.changeset, alert_format_set: alert_format)

          # IO.inspect(changeset, label: "changeset radio email")

          {:noreply, assign(socket, :changeset, changeset)}

        # end
        alert_format === AlertFormatTypesMap.get_alert("SMS") ->
          changeset =
            Ecto.Changeset.change(socket.assigns.changeset, alert_format_set: alert_format)

          # IO.inspect(changeset, label: "changeset radio SMS")

          {:noreply, assign(socket, :changeset, changeset)}

        true ->
          IO.puts("upsert handle_event: NO keys")
          {:noreply, socket}
      end
    end
  end
  def handle_event("generate", _params, socket) do
    # append a code to the socket
    case IndexUtils.handle_generate_verification_code(socket) do
      {:ok, socket} ->
        {:noreply, socket}

      {:error, error} ->
        IO.inspect(error, label: "An error occured in upsert handle_event:generate")
        {:noreply,
        socket
        |> put_flash(:error, "Sorry, a system error has occured in saving verification code.")}
    end
  end
  # handle save for new and edit
  def handle_event("save", %{"user" => user_params}, socket) do
    current_employee = socket.assigns[:current_employee]
    # IO.inspect(user_params, label: "user_params")
    IO.inspect(socket.assigns.live_action, label: "handle_event upsert: live_action")
    # if !socket.assigns.changeset.valid? do
    #   # no submit if validation errors
    #   handle_event("validate", %{"user" => user_params}, socket)
    # else
      case socket.assigns.live_action do
        live_action when live_action in [:edit] ->
          if EmployeeAuth.has_user_edit_permissions?(socket, current_employee) do
            IndexUtils.save_user(socket, socket.assigns.live_action, user_params)
          else
            socket =
              socket
              |> put_flash(:error, "Insuffient permissions to perform user edit")
              |> push_redirect(to: socket.assigns.return_to)

            {:noreply, socket}
          end

        # creating new employee
        :new ->
          if EmployeeAuth.has_user_add_permissions?(socket, current_employee) do
            IndexUtils.save_user(socket, socket.assigns.live_action, user_params)
          else
            socket =
              socket
              |> put_flash(:error, "Insuffient permissions to perform user add")
              |> push_redirect(to: socket.assigns.return_to)

            {:noreply, socket}
          end

        # returning to form with changeset; on existing users reject
        :insert ->
          # IO.inspect(socket.assigns.live_action, label: "AAAAAA")
          if EmployeeAuth.has_user_add_permissions?(socket, current_employee) do
            IndexUtils.save_user(socket, socket.assigns.live_action, user_params)
          else
            socket =
              socket
              |> put_flash(:error, "Insuffient permissions to perform user add")
              |> push_redirect(to: socket.assigns.return_to)

            {:noreply, socket}
          end

        :select ->
          # IO.inspect(socket.assigns.live_action, label: "AAAAAA")
          if EmployeeAuth.has_user_add_permissions?(socket, current_employee) do
            activate_user(socket, socket.assigns.live_action, user_params)
          else
            socket =
              socket
              |> put_flash(:error, "Insuffient permissions to perform user add")
              |> push_redirect(to: socket.assigns.return_to)

            {:noreply, socket}
          end

        _ ->
          {:noreply, socket}
      end
    # end
  end

  # back from :display - on :new when existing users found
  defp activate_user(socket, live_action, _user_params) when live_action in [:select, :insert] do
    # should have access to use passed from display
    user = socket.assigns[:user]
    # check if user is already active
    if user && user.is_active? do
      socket =
        socket
        |> put_flash(
          :warning,
          "This user is aleady active and should be in the main list. Look through your list of users again."
        )

      {:noreply, socket}
    else
      with user_changeset <- Patients.change_user(user, %{is_active?: true}),
          # if changes are valid
          true <- Ecto.Changeset.get_change(user_changeset, :is_active?) do

            case TurnStile.Repo.update(user_changeset) do
              {:ok, user} ->
                IO.inspect(user, label: "activate_user :update user")
                # send update to :index - refresh the list
                send(self(), :update)
                # TODO: redirect to index
                socket =
                  socket
                  |> put_flash(
                    :success,
                    "User activated successfully. User should now be in the main list.")
                {:noreply, socket}

              {:error, %Ecto.Changeset{} = changeset} ->
                socket =
                  socket
                  |> put_flash(:error, "User not activated")

                {:noreply, assign(socket, :changeset, changeset)}
            end
      end
    end
  end

  def maybe_assign_code(socket, nil), do: socket
  def maybe_assign_code(socket, %{"code" => code}) do
    socket
    |> assign(:code, code)
  end
end
