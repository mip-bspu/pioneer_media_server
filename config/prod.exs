import Config

# Configures Swoosh API Client
config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: MediaServer.Finch

# Disable Swoosh Local Memory Storage
config :swoosh, local: false

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.

config :media_server,
  queue_tag: "city",
  queue_parent: nil,
  initial_tags: ["city", "blg"]

config :media_server, # sync_files
  dist_content: "./files/",
  interval_sync_check: 10 * 1000,
  chunk_size: 2000

config :media_server, # journal
  interval_clear_journal: 3 * 60 * 1000,
  days_for_storage: 60

config :pioneer_rpc, connection_string: "amqp://guest:guest@localhost:5672"
