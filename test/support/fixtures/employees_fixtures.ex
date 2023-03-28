defmodule TurnStile.EmployeeFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TurnStile.Staff` context.
  """

  def unique_employee_email, do: "employee#{System.unique_integer()}@example.com"
  def valid_employee_password, do: "hello world!"

  def valid_employee_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_employee_email(),
      password: valid_employee_password()
    })
  end

  def employee_fixture(attrs \\ %{}) do
    {:ok, employee} =
      attrs
      |> valid_employee_attributes()
      |> TurnStile.Staff.register_employee()

    employee
  end

  def extract_employee_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  @doc """
  Generate a employee.
  """
  def employee_fixture(attrs2 \\ %{}) do
    {:ok, employee} =
      attrs2
      |> Enum.into(%{

      })
      |> TurnStile.Staff.create_employee()

    employee
  end
end
