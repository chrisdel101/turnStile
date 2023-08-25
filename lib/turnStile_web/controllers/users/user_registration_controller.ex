defmodule TurnStileWeb.UserRegistrationController do
  use TurnStileWeb, :controller
  alias TurnStile.Patients
  alias TurnStile.Patients.UserToken
  alias TurnStile.Patients.User

  @moduledoc """
    UserRegistrationController
  - renders the template for users given a verification code to self register
  """

  # workflow for token generation and validation
  # y = TurnStile.Patients.UserToken.generate_user_verification_code(3)
  # {ur, token, enc_token} = TurnStile.Patients.build_and_insert_user_verification_code_token(y)
  # {_,query}  = TurnStile.Patients.UserToken.encoded_verification_token_and_context_query(enc_token, "verification")
  # TurnStile.Repo.one(query)

  def index(conn, _params) do
    conn
    |> render("index.html")
  end

  # def new(conn, %{"code" => %{"verification_code" => verification_code }}) do

  #   IO.inspect(verification_code, label: "code")
  # end

  def new(conn, %{"code" => %{"verification_code" => verification_code}}) do
    # process code to get a token
    {encoded_token, _user_token} = UserToken.build_verification_code_token(verification_code)
    # check user verification code as token exists
    case Patients.confirm_user_verification_token(encoded_token) do
      {:ok, user_token} ->
        IO.inspect(user_token, label: "user_token")
        changeset = TurnStile.Patients.create_user()

        conn
        |> render("new.html",
          changeset: changeset,
          token: encoded_token,
          organization_id: user_token.organization_id
        )

      {nil, :not_found} ->
        {nil, :not_found}
        # # no users matching - b/c user session does not match any users
        IO.puts("user verification token:  not_found")

        conn
        |> put_flash(:error, "Sorry, your URL link is invalid. Ask staff for another one.")
        |> redirect(to: "/")

      # valid request but expired - will be deleted on this call
      {:expired, user_token} ->
        IO.inspect(user_token, label: "user_token")
        # delete expired token
        Patients.delete_verification_token(user_token)
        IO.puts("user_auth:  token expired and deleted")

        conn
        |> put_flash(
          :error,
          "Sorry, that verification code is expired. Ask staff for another one."
        )
        |> redirect(to: "/")

      # syntax error in the input; token cannot be a single digit, else error; whitepace, etc.
      :invalid_input_token ->
        conn
        |> put_flash(
          :error,
          "Sorry, a system error has occured. Make sure there no extra spaces or symbols in the URL, and that the URL is correct. Contact staff if this persists."
        )
        |> redirect(to: "/")
    end
  end

  def new(conn, %{"token" => token, "id" => organization_id}) do
    # IO.inspect(Patients.confirm_user_verification_token(token), label: "HERE")
    # delete any aged-out tokens from previous sessions
    Patients.delete_expired_verification_tokens()
    # check user verification token exists
    case Patients.confirm_user_verification_token(token) do
      {:ok, _user_token} ->
        changeset = TurnStile.Patients.create_user()

        conn
        |> render("new.html",
          changeset: changeset,
          token: token,
          organization_id: organization_id
        )

      {nil, :not_found} ->
        {nil, :not_found}
        # # no users matching - b/c user session does not match any users
        IO.puts("user verification token:  not_found")

        conn
        |> put_flash(:error, "Sorry, your URL link is invalid. Ask staff for another one.")
        |> redirect(to: "/")

      # valid request but expired - will be deleted on this call
      {:expired, user_token} ->
        IO.inspect(user_token, label: "user_token")
        # delete expired token
        Patients.delete_verification_token(user_token)
        IO.puts("user_auth:  token expired and deleted")

        conn
        |> put_flash(
          :error,
          "Sorry, that verification code is expired. Ask staff for another one."
        )
        |> redirect(to: "/")

      # syntax error in the input; token cannot be a single digit, else error; whitepace, etc.
      :invalid_input_token ->
        conn
        |> put_flash(
          :error,
          "Sorry, a system error has occured. Make sure there no extra spaces or symbols in the URL, and that the URL is correct. Contact staff if this persists."
        )
        |> redirect(to: "/")
    end
  end

  def handle_create(conn, %{"user" => user_params, "token" => token, "id" => organization_id}) do
    case Patients.confirm_user_verification_token(token) do
      # if token exists, even exipired, send user form
      {_, %UserToken{} = user_token} ->
        case handle_form_validation(user_params) do
          {:ok, _changeset} ->
            # send form params to employee
            Phoenix.PubSub.broadcast(
              TurnStile.PubSub,
              PubSubTopicsMap.get_topic("USER_REGISTRATION"),
              {:user_registation_form,
               %{
                 user_params: %{
                   first_name: "Joe",
                   last_name: "Schmoe",
                   phone: "3065190138",
                   email: "arssonist@yahoo.com",
                   alert_format_set: "email",
                   health_card_num: 9999,
                   date_of_birth: Date.from_iso8601!("1900-01-01")
                 }
               }}
            )

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
            |> render("new.html",
              changeset: changeset,
              token: token,
              organization_id: organization_id
            )
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

  defp handle_form_validation(user_params) do
    changeset = Patients.create_user(user_params)

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  def quick_new(conn, %{"token" => token, "id" => organization_id}) do
    # changeset = TurnStile.Patients.create_user()
    conn
    |> render("new.html",
      organization_id: organization_id,
      changeset: TurnStile.Patients.create_user(),
      token: token
    )
  end

  def quick_send(conn, %{"id" => organization_id, "token" => token}) do
    Phoenix.PubSub.broadcast(
      TurnStile.PubSub,
      PubSubTopicsMap.get_topic("USER_REGISTRATION"),
      {:user_registation_form,
       %{
         user_params: %{
           first_name: "Joe",
           last_name: "Schmoe",
           phone: "3065190138",
           email: "arssonist@yahoo.com",
           alert_format_set: "email",
           health_card_num: 9999,
           date_of_birth: Date.from_iso8601!("1900-01-01")
         }
       }}
    )

    conn
    |> put_flash(:success, "Thank your. Your form was successfully submitted")
    |> render("new.html",
      organization_id: organization_id,
      changeset: TurnStile.Patients.create_user(),
      token: token
    )
  end
end
