defmodule TurnStileWeb.Router do
  use TurnStileWeb, :router


  import TurnStileWeb.EmployeeAuth
  import TurnStileWeb.OrganizationController
  import TurnStileWeb.AlertController

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {TurnStileWeb.LayoutView, :root}
    # plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_employee
  end

  pipeline :api do
    plug :accepts, ["json"]
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
    pipe_through [:browser, :organization_setup?,:req_auth_after_org_setup?]

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

    get "/", PageController, :index
    get "/setup", SetupController, :new
    get "/organizations/search", OrganizationController, :search_get
    post "/organizations/search", OrganizationController, :search_post

    resources "/organizations", OrganizationController, except: [:show] do
      resources "/employees", EmployeeController, except: [:show, :new] do
          resources "/users", UserController
        end
      end
    get "/organizations/:param/employees/:id", EmployeeController, :show
    get "/organizations/:param/employees/:id/users/:id/alert", AlertController, :send_alert
    get "/organizations/:param", OrganizationController, :show

  end
end
