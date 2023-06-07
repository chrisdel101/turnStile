defmodule TurnStile.Staff.EmployeeNotifier do
  import Swoosh.Email

  alias TurnStile.Mailer


  # Delivers the email using the application mailer - called by the funcs belo
  defp deliver(recipient, subject, body) do
    # systax here requires this for domain in sender - for mailgun
    recipient = if Mix.env == :prod, do: recipient, else: System.get_env("DEV_EMAIL")
    email =
      new()
      |> to(recipient)
      |> from({"TurnStile","mailgun@#{System.get_env("MAILGUN_DOMAIN")}"} )
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
  end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(employee, url) do
    deliver(employee.email, "Confirmation instructions", """

    ==============================

    Hi #{employee.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a employee password.
  """
  def deliver_reset_password_instructions(employee, url) do
    deliver(employee.email, "Reset password instructions", """

    ==============================

    Hi #{employee.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a employee email.
  """
  def deliver_update_email_instructions(employee, url) do
    deliver(employee.email, "Update email instructions", """

    ==============================

    Hi #{employee.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
  @doc """
  Deliver instructions to update a employee email.
  """
  def deliver_employee_account_setup_instructions(employee, url) do
    deliver(employee.email, "Update email instructions", """

    ==============================

    Hi #{employee.email},

    An account has been created for you. Visit the URL below to continue the your account setup:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
  @doc """
  Deliver instructions to update a employee email.
  """
  def deliver_welcome_email_init_employee_instructions(employee) do
    deliver(employee.email, "Welcome Email", """

    ==============================

    Hi #{employee.email},

    Weclome to TurnStile!

    Your login email is #{employee.email}.
    Your password is #{employee.password}.

    This method of authenitcation is very insecure and should not be used in production. Please change your password immediately.

    If you didn't request this account, please ignore this email.

    ==============================
    """)
  end
end
