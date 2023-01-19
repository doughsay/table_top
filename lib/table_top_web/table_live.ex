defmodule TableTopWeb.TableLive do
  use TableTopWeb, :live_view

  alias TableTop.PubSub
  alias TableTopWeb.Presence

  @presence "table:presence"
  @mousemove "table:mousemove"

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <p id="mouse" phx-hook="mouse">Connected Users:</p>
    <ul>
      <li :for={{username, _details} <- @users}>
        <%= username %>
      </li>
    </ul>
    <.pointer :for={{username, {x, y}} <- @mouse_positions} username={username} x={x} y={y} />
    """
  end

  defp pointer(assigns) do
    ~H"""
    <div class="absolute h-6 w-6 bg-red-600" style={"top: #{@y}px; left: #{@x}px;"}>
      <%= @username %>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      username = socket.private.connect_params["username"]

      {:ok, _} =
        Presence.track(self(), @presence, username, %{
          username: username,
          joined_at: :os.system_time(:seconds)
        })

      :ok = Phoenix.PubSub.subscribe(PubSub, @mousemove)

      Phoenix.PubSub.subscribe(PubSub, @presence)
    end

    {
      :ok,
      socket
      |> assign(:current_user, socket.private.connect_params["username"])
      |> assign(:users, %{})
      |> assign(:mouse_positions, %{})
      |> handle_joins(Presence.list(@presence))
    }
  end

  @impl Phoenix.LiveView
  def handle_event("mousemove", %{"coordinates" => %{"x" => x, "y" => y}}, socket) do
    Phoenix.PubSub.broadcast(
      PubSub,
      @mousemove,
      {@mousemove, socket.assigns.current_user, {x, y}}
    )

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({@mousemove, username, {x, y}}, socket) do
    if username != socket.assigns.current_user do
      {:noreply, update(socket, :mouse_positions, &Map.put(&1, username, {x, y}))}
    else
      {:noreply, socket}
    end
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    {
      :noreply,
      socket
      |> handle_leaves(diff.leaves)
      |> handle_joins(diff.joins)
    }
  end

  defp handle_joins(socket, joins) do
    Enum.reduce(joins, socket, fn {username, %{metas: [meta | _]}}, socket ->
      update(socket, :users, &Map.put(&1, username, meta))
    end)
  end

  defp handle_leaves(socket, leaves) do
    Enum.reduce(leaves, socket, fn {username, _}, socket ->
      socket
      |> update(:users, &Map.delete(&1, username))
      |> update(:mouse_positions, &Map.delete(&1, username))
    end)
  end
end
