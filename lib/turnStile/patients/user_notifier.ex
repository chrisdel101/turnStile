defmodule TurnStile.Patients.UserNotifier do
  import Swoosh.Email
  alias TurnStile.Mailer
  @json TurnStile.Utils.read_json("alert_text.json")

  # Delivers the email using the application mailer - called by the funcs belo
  def deliver(alert, subject, body) do
    # IO.inspect(alert, label: "UserNotifier deliver alert")

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
  def deliver_initial_alert(_user, alert, url) do
    if !is_nil(alert) do
      case deliver(alert, alert.title, """
           ==============================

           Hi #{alert.to},

           #{@json["alerts"]["request"]["email"]["initial"]["body"]}

           #{url}

           ==============================
           """) do
        {:ok, email} ->
          {:ok, email}

        {:error, error} ->
          {:error, error}
      end
    else
      IO.puts("Error: deliver_initial_alert user inputs nil")
      nil
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_custom_alert(_user, alert, url) do
    # IO.inspect(alert, label: "alert")
    # IO.inspect(url, label: "URL")
    if !is_nil(alert) do
      case deliver(alert, alert.title, """

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
