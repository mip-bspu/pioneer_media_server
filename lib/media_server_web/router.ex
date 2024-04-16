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

    get("/users", AdminController, :list_users)
  end

  scope "/", MediaServerWeb do
    pipe_through :api

    get("/tags", TagsController, :list)

    post("/action", ActionController, :create)
    get("/action", ActionController, :list)
    get("/action/period", ActionController, :list_from_period)
    put("/action/:uuid", ActionController, :update)
    delete("/action/:uuid", ActionController, :delete)
    get("/action/files/:action_uuid", FilesController, :list)

    get("/files/:uuid/file", FilesController, :content)
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
