defmodule TurnStileWeb.Router do
  use TurnStileWeb, :router

  import TurnStileWeb.AdminAuth

  import TurnStileWeb.TestController
  import TurnStileWeb.EmployeeAuth
  import TurnStileWeb.OrganizationController
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {TurnStileWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_admin
    plug :fetch_current_employee
    # used in template
    plug TurnStileWeb.Plugs.RouteType, "non-admin"
    plug TurnStileWeb.Plugs.EmptyParams
    plug :first_org_form_submit?, false
    plug :fetch_current_organization
    plug :set_test_current_employee
  end

  pipeline :api do
    plug :accepts, ["json"]
    # This is the line that should be added
    post "/sms_messages", TurnStileWeb.AlertController, :receive
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only employees to access it.
  # If your application does not have an employees-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TurnStileWeb.Telemetry
    end
  end

  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  # if Mix.env() == :test do
  scope "/test" do
    pipe_through :browser

    post "/organizations/:id/employees/register",
         TurnStileWeb.TestController,
         :quick_register_employee

    # get "/", TurnStileWeb.TestController, :employee_register
    get "/organizations/:id/employees/register",
        TurnStileWeb.TestController,
        :employee_register_page
  end

  # end

  scope "/", TurnStileWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/clear_sessions", PageController, :clear_sessions
  end

  ## Authentication routes

  scope "/organizations/:id", TurnStileWeb do
    pipe_through [:browser, :redirect_if_employee_is_authenticated]

    get "/employees/log_in", EmployeeSessionController, :new
    post "/employees/log_in", EmployeeSessionController, :create
    get "/employees/reset_password", EmployeeResetPasswordController, :new
    post "/employees/reset_password", EmployeeResetPasswordController, :create
    get "/employees/reset_password/:token", EmployeeResetPasswordController, :edit
    put "/employees/reset_password/:token", EmployeeResetPasswordController, :update
  end

  scope "/organizations/:id", TurnStileWeb do
    pipe_through [:browser, :require_authenticated_employee]

    get "/employees/settings", EmployeeSettingsController, :edit
    put "/employees/settings", EmployeeSettingsController, :update
    get "/employees/settings/confirm_email/:token", EmployeeSettingsController, :confirm_email
  end

  scope "/organizations/:id", TurnStileWeb do
    pipe_through [
      :browser,
      :organization_setup?,
      :require_authenticated_employee_post_org_setup,
      :require_register_access_employee
    ]

    get "/employees/register", EmployeeRegistrationController, :new
    post "/employees/register", EmployeeRegistrationController, :create
  end

  scope "/organizations/:id", TurnStileWeb do
    pipe_through [:browser]

    delete "/employees/log_out", EmployeeSessionController, :delete
    get "/employees/confirm", EmployeeConfirmationController, :new
    post "/employees/confirm", EmployeeConfirmationController, :create
    get "/employees/setup/:token", EmployeeConfirmationController, :setup
    get "/employees/confirm/:token", EmployeeConfirmationController, :confirm
    post "/employees/confirm/:token", EmployeeConfirmationController, :update
    put "/employees/confirm/:token", EmployeeConfirmationController, :update
  end

  scope "/", TurnStileWeb do
    pipe_through [:browser, :require_authenticated_employee]

    resources "/organizations", OrganizationController, except: [:show, :index, :new, :create] do
      resources "/employees", EmployeeController, except: [:new, :edit, :update, :index]
    end

    post(
      "/organizations/:organization_id/employees/:employee_id/users/:user_id/alert",
      AlertController,
      :create
    )

    live "/organizations/:organization_id/employees/:employee_id/users/", UserLive.Index, :index

    live "/organizations/:organization_id/employees/:employee_id/users/new", UserLive.Index, :new

    live "/organizations/:organization_id/employees/:employee_id/users/:id/edit",
      UserLive.Index,
      :edit

    live "/organizations/:organization_id/employees/:employee_id/users/:user_id",
      UserLive.Show,
      :show
  end

  # employee edit and update req write access
  scope "/organizations/:organization_id/employees/:id", TurnStileWeb do
    pipe_through [:browser, :require_authenticated_employee, :require_edit_access_employee]

    get "/edit", EmployeeController, :edit
    put "/edit", EmployeeController, :update
  end

  # /employees
  scope "/organizations/:organization_id/", TurnStileWeb do
    pipe_through [
      :browser,
      :require_authenticated_employee,
      :require_edit_access_employee
    ]
  # employee edit action - req e access
    get "/employees", EmployeeController, :index, as: :organization_employee
  end

  # /organizations non_authenciated
  scope "/organizations", TurnStileWeb do
    pipe_through :browser

    get "/search", OrganizationController, :search_get
    post "/search", OrganizationController, :search_post

    get "/new", OrganizationController, :new
    post "/new", OrganizationController, :handle_new
    post "/", OrganizationController, :create

    # get "/new-organization", OrganizationController, :confirm_organization
    get "/:id", OrganizationController, :show
  end

  scope "/organizations", TurnStileWeb do
    pipe_through [:browser, :require_authenticated_admin]
    # only admins can see all organizations
    get "/", OrganizationController, :index
  end

  ## Admin Authentication routes

  scope "/", TurnStileWeb do
    pipe_through [:browser, :redirect_if_admin_is_authenticated]

    get "/admin/register", AdminRegistrationController, :new
    post "/admin/register", AdminRegistrationController, :create
    get "/admin/log_in", AdminSessionController, :new
    post "/admin/log_in", AdminSessionController, :create
    get "/admin/reset_password", AdminResetPasswordController, :new
    post "/admin/reset_password", AdminResetPasswordController, :create
    get "/admin/reset_password/:token", AdminResetPasswordController, :edit
    put "/admin/reset_password/:token", AdminResetPasswordController, :update
  end

  scope "/admin", TurnStileWeb do
    pipe_through :browser

    delete "/log_out", AdminSessionController, :delete
    get "/confirm", AdminConfirmationController, :new
    post "/confirm", AdminConfirmationController, :create
    get "/confirm/:token", AdminConfirmationController, :edit
    post "/confirm/:token", AdminConfirmationController, :update
  end

  scope "/admin", TurnStileWeb do
    pipe_through [:browser, :require_authenticated_admin]

    get "/settings", AdminSettingsController, :edit
    put "/settings", AdminSettingsController, :update
    get "/settings/confirm_email/:token", AdminSettingsController, :confirm_email

    resources "/admins", AdminController, except: [:new]
    get "/", AdminController, :home
  end
end
