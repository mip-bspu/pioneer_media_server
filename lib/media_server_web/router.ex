defmodule MediaServerWeb.Router do
  use MediaServerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/auth", MediaServerWeb do
    pipe_through :api

    post("/", SessionController, :authenticate)
    post("/logout", SessionController, :logout)
  end

  scope "/admin", MediaServerWeb do
    pipe_through :api

    post("/user", AdminController, :create_user)
    get("/users", AdminController, :list_users)
    post("/users/:id/active", AdminController, :set_active)
    put("/users/:id", AdminController, :update_user)

    get("/tags", TagsController, :list)
    post("/tag", TagsController, :create)
    delete("/tag/:id", TagsController, :delete)
    get("/groups", AdminController, :list_groups)
  end

  scope "/devices", MediaServerWeb do
    pipe_through :api

    post("/", DevicesController, :create)
    get("/", DevicesController, :list)
    get("/min", DevicesController, :min_list)
    delete("/:token", DevicesController, :delete)
  end

  scope "/action", MediaServerWeb do
    pipe_through :api

    post("/", ActionController, :create)
    put("/:uuid", ActionController, :update)
    delete("/:uuid", ActionController, :delete)
    put("/:uuid/files", ActionController, :update_files_data)

    get("/", ActionController, :list)
    get("/period", ActionController, :list_from_period)
    get("/files/:action_uuid", FilesController, :list)
  end

  scope "/journal", MediaServerWeb do
    pipe_through :api

    get("/", JournalController, :list)
  end

  scope "/", MediaServerWeb do
    pipe_through :api

    get("/setup", ServerController, :setup)
    get("/files/:uuid/file", FilesController, :content)
  end

  scope "/client", MediaServerWeb do
    pipe_through :api

    get("/", ClientController, :initialize)
    get("/schedule", ClientController, :schedule)
    get("/content", ClientController, :content)
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:media_server, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: MediaServerWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
