defmodule TurnStileWeb.UserLive.FormComponent do
  # handles the logic for the modals
  use TurnStileWeb, :live_component

  alias TurnStile.Patients

  @impl true
  def update(%{user: user} = assigns, socket) do
    changeset = Patients.change_user(user)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Patients.change_user(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    IO.inspect(socket.assigns.action, label: "action")
    save_user(socket, socket.assigns.action, user_params)
    socket =
      socket
      |> put_flash(:error, "NONONONON ")
      |> assign(:socket, socket)
      |> assign(:flash, %{"info" => "some meesage"})


    {:noreply, put_flash(socket, :error, "NONONONON ")}
  end

  defp save_user(socket, :edit, user_params) do
    case Patients.update_user(socket.assigns.user, user_params) do
      {:ok, user} ->
        IO.inspect("OKAY")
        IO.inspect(user)

        {:noreply,
         socket
         |> put_flash(:info, "User updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset)
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_user(socket, :new, user_params) do
    case Patients.create_user(user_params) do
      {:ok, user} ->

        {:noreply,
         socket
         |> put_flash(:info, "User created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect("errir")
        IO.inspect(changeset)

        socket =
          socket
          |> put_flash(:error, "User No")
          |> assign(:socket, socket)

        # IO.inspect(socket, label: "socket")
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
