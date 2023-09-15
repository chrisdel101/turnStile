defmodule TurnStile.Company.Organization do
  use Ecto.Schema
  import Ecto.Changeset


  schema "organizations" do
    field :email, :string
    field :name, :string
    field :slug, :string
    field :phone, :string
    field :timezone, :string, default: "Etc/UTC"
    ##### CONTROL FLOW VARIABLES ######
    # require initial/first employee to confirm account before accessing
    field :require_init_employee_confirmation, :boolean, default: true
    #  after create normal employee, require PW change + means cannot use default password
    field :employee_create_setup_is_required, :boolean, default: true
    # after create initital employee log_in directly; else manual login needed
    field :employee_create_init_auto_login, :boolean, default: true
    # after create normal employee log_in directly, else manual login needed
    field :employee_create_auto_login, :boolean, default: false
    # after confirm log_in employee, else with need login after account confirmation
    field :employee_confirm_auto_login, :boolean, default: true
    # allow pending users to enter queue,; else only confirmed users
    field :user_allow_pending_into_queue, :boolean, default: true



    ###### RELATIONSHIPS ####
    # org many employees <-> employees can belong to many orgs
    many_to_many :employees, TurnStile.Staff.Employee, join_through: "organization_employees", on_replace: :delete
     # org many roles - each role belongs to one org
    has_many :roles, TurnStile.Roles.Role
    has_many :users, TurnStile.Patients.User
     # org many tokens - each token belongs assoc w one org
    has_many :user_tokens, TurnStile.Patients.User
    has_many :alerts, TurnStile.Alerts.Alert

    timestamps()


  end

  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name, :email, :phone, :slug, :timezone, :require_init_employee_confirmation, :employee_create_setup_is_required, :employee_create_init_auto_login, :employee_create_auto_login, :employee_confirm_auto_login, :user_allow_pending_into_queue])
    |> validate_required([:name, :slug])
    |> validate_email()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
  end
end
