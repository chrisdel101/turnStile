defmodule TurnStile.Patients.UserNotifier do
  import Swoosh.Email
  alias TurnStile.Mailer

  # Delivers the email using the application mailer - called by the funcs belo
  def deliver(alert, subject, body) do

    email =
      new()
      |> to(alert.to)
      |> from({"TurnStile", "mailgun@#{System.get_env("MAILGUN_DOMAIN")}"})
      |> subject(subject)
      |> text_body(body)
      IO.inspect(email, label: "email")
    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    else
      {:error, error} ->
        {:error, error}
    end
  end
  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_initial_alert(user, url) do
    if !is_nil(user) && !is_nil(user.email) do
      deliver(user.email, "Initial Alert", """

      ==============================

      Hi #{user.email},

      This is your initial alert from TurnStile.

      You will be upated here when it is your turn to be admitted.

      To cancel your stop, visit the link below to 'cancel'

      #{url}

      ==============================
      """)
    else
      IO.puts("Error: deliver_initial_alert user inputs nil")
      nil
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_custom_alert(_user, alert, url) do
    IO.inspect(alert, label: "alert")
    IO.inspect(url, label: "URL")
    if !is_nil(alert) do
      case deliver(alert, "Custom Alert", """

      ==============================

      Hi #{alert.to},

      #{alert.title}.

      #{alert.body}

      #{url}

      ==============================
      """) do
        {:ok, email} ->
          {:ok, email}

        {:error, error} ->
          {:error, error}
      end
    else
      IO.puts("Error: deliver_custom_alert inputs nil")
      nil
    end
  end
end
