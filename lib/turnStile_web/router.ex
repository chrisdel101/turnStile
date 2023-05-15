defmodule TurnStileWeb.Router do
  use TurnStileWeb, :router

  import TurnStileWeb.AdminAuth

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
  end

  pipeline :api do
    plug :accepts, ["json"]
    # This is the line that should be added
    post "/sms_messages", TurnStileWeb.AlertController, :receive
  end

  # Other scopes may use custom stacks.
  # scope "/api", TurnStileWeb do
  #   pipe_through :api
  # end

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

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
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
    pipe_through [:browser, :organization_setup?, :req_auth_after_org_setup?]

    get "/employees/register", EmployeeRegistrationController, :new
    post "/employees/register", EmployeeRegistrationController, :create
  end

  scope "/organizations/:id", TurnStileWeb do
    pipe_through [:browser]

    delete "/employees/log_out", EmployeeSessionController, :delete
    get "/employees/confirm", EmployeeConfirmationController, :new
    post "/employees/confirm", EmployeeConfirmationController, :create
    get "/employees/confirm/:token", EmployeeConfirmationController, :edit
    post "/employees/confirm/:token", EmployeeConfirmationController, :update
  end

  scope "/", TurnStileWeb do
    pipe_through :browser

    live "/thermostat", TurnStileLive

    get "/", PageController, :index
    get "/setup", SetupController, :new
    get "/organizations/search", OrganizationController, :search_get
    post "/organizations/search", OrganizationController, :search_post

    resources "/organizations", OrganizationController, except: [:show, :index] do
      resources "/employees", EmployeeController, except: [:show, :new]
      # do
      #   resources "/users", UserLive.Index, except: [:show]
      # end
    end

    get "/organizations/:param/employees/:id", EmployeeController, :show

    get "/organizations/:param", OrganizationController, :show

    post "/organizations/:organization_id/employees/:employee_id/users/:user_id/alert",
         AlertController,
         :create

    live "/organizations/:organization_id/employees/:employee_id/users/", UserLive.Index, :index
    live "/organizations/:organization_id/employees/:employee_id/users/new", UserLive.Index, :new

    live "/organizations/:organization_id/employees/:employee_id/users/:id/edit",
         UserLive.Index,
         :edit

    live "/organizations/:organization_id/employees/:employee_id/users/:user_id",
         UserLive.Show,
         :show
  end

  scope "/organizations", TurnStileWeb do
    # :require_authenticated_admin, #:company_only_route
    pipe_through [:browser]

    get "/", OrganizationController, :index
  end

  # live "/users", UserLive.Index, :index
  # live "/users/new", UserLive.Index, :new
  # live "/users/:id/edit", UserLive.Index, :edit

  # live "/users/:id", UserLive.Show, :show
  # live "/users/:id/show/edit", UserLive.Show, :edit
  ## Authentication routes

  scope "/", TurnStileWeb do
    pipe_through [:browser, :redirect_if_admin_is_authenticated]

    get "/admins/register", AdminRegistrationController, :new
    post "/admins/register", AdminRegistrationController, :create
    get "/admins/log_in", AdminSessionController, :new
    post "/admins/log_in", AdminSessionController, :create
    get "/admins/reset_password", AdminResetPasswordController, :new
    post "/admins/reset_password", AdminResetPasswordController, :create
    get "/admins/reset_password/:token", AdminResetPasswordController, :edit
    put "/admins/reset_password/:token", AdminResetPasswordController, :update
  end

  scope "/admins", TurnStileWeb do
    pipe_through [:browser, :require_authenticated_admin]

    get "/settings", AdminSettingsController, :edit
    put "/settings", AdminSettingsController, :update
    get "/settings/confirm_email/:token", AdminSettingsController, :confirm_email

    resources "/", AdminController
  end

  scope "/admins", TurnStileWeb do
    pipe_through [:browser]

    delete "log_out", AdminSessionController, :delete
    get "confirm", AdminConfirmationController, :new
    post "confirm", AdminConfirmationController, :create
    get "confirm/:token", AdminConfirmationController, :edit
    post "confirm/:token", AdminConfirmationController, :update

  end
end
