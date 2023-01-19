defmodule TableTopWeb.Presence do
  use Phoenix.Presence,
    otp_app: :table_top,
    pubsub_server: TableTop.PubSub
end
