defmodule TurnStileWeb.UserRegistrationController do
  use TurnStileWeb, :controller
  alias TurnStile.Patients
  alias TurnStile.Patients.UserToken
  alias TurnStile.Patients.User

  @moduledoc """
    UserRegistrationController
  - renders the template for users given a verification code to self register
  """

  alias TurnStileWeb.UserAuth
  # y = TurnStile.Patients.UserToken.generate_user_verification_code(3)
  # {ur, token, enc_token} = TurnStile.Patients.build_and_insert_user_verification_code_token(y)
  # {_,query}  = TurnStile.Patients.UserToken.encoded_verification_token_and_context_query(enc_token, "verification")
  # TurnStile.Repo.one(query)
  def new(conn, %{"token" => token}) do
    # IO.inspect(Patients.confirm_user_verification_token(token), label: "HERE")
    case Patients.confirm_user_verification_token(token) do
      {:ok, _user_token} ->
         changeset = TurnStile.Patients.create_user()
         conn
         |> render("new.html", changeset: changeset, token: token)
      {nil, :not_found} ->
        {nil, :not_found}
        # # no users matching - b/c user session does not match any users
        IO.puts("user verification token:  not_found")
        conn
        |> put_flash(:error, "Sorry, your URL link is invalid. Ask staff for another one.")
        |> redirect(to: "/")

      {:expired, user_token} ->
        IO.inspect(user_token, label: "user_token")
        # valid request but expired - will be deleted on this call
        # delete expirted token
        Patients.delete_verification_token(user_token)
        IO.puts("user_auth:  token expired and deleted")
        # update user alert status
        # push_user_and_interface_updates(conn, user_id)

        conn
        |> put_flash(
          :error,
          "Sorry, that verification code is expired. Ask staff for another one."
        )
        |> redirect(to: "/")
       # token cannot be a single digit, else error
      :invalid_input_token ->
        conn
        |> put_flash(
          :error,
          "Sorry, a system error has occured. Make sure there no extra spaces or symbols in the URL, and that the URL is correct. Contact staff if this persists."
        )
        |> redirect(to: "/")
    end
  end

  def handle_create(conn, %{"user" => user_params, "token" => token}) do
    case Patients.confirm_user_verification_token(token) do
      # if token exists, even exipired, send user form
        {_, %UserToken{} = user_token} ->
        case handle_form_validation(user_params) do
          {:ok, _changeset} ->
            # send form params to employee
            Phoenix.PubSub.broadcast(
              TurnStile.PubSub,
              PubSubTopicsMap.get_topic("USER_REGISTRATION"),
              {:user_registation_form, %{user_params: user_params}})
            # delete token
            Patients.delete_verification_token(user_token)
            # changeset = TurnStile.Patients.create_user()
            conn
            |> put_flash(:success, "Thank your. Your form was successfully submitted")
            |> redirect(to: Routes.page_path(conn, :index))
          {:error, _changeset} ->
            # send validation errors to form
            changeset =
            %User{}
            |> Patients.change_user(user_params)
            |> Map.put(:action, :validate)
            conn
            |> render("new.html", changeset: changeset, token: token)
        end
      {nil, :not_found} ->
        {nil, :not_found}
        # # no users matching - b/c user session does not match any users
        IO.puts("user verification token:  not_found")
        conn
        |> put_flash(:error, "Sorry, your URL link is invalid. Ask staff for another one.")
        |> redirect(to: "/")
       # token cannot be a single digit, else error
      :invalid_input_token ->
        conn
        |> put_flash(
          :error,
          "Sorry, a system error has occured. Make sure there no extra spaces or symbols in the URL, and that the URL is correct. Contact staff if this persists."
        )
        |> redirect(to: "/")
    end
  end


  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end

  defp handle_form_validation(user_params) do
    changeset = Patients.create_user(user_params)
    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end
end
