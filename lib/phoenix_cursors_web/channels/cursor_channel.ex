defmodule PhoenixCursorsWeb.CursorChannel do
  alias PhoenixCursorsWeb.Presence
  use PhoenixCursorsWeb, :channel

  @impl true
  def handle_in("move", %{"x" => x, "y" => y}, socket) do
    {:ok, _} =
      Presence.update(socket, socket.assigns.current_user, fn previousState ->
        Map.merge(
          previousState,
          %{
            online_at: inspect(System.system_time(:second)),
            x: x,
            y: y,
            color: PhoenixCursors.Colors.getHSL(socket.assigns.current_user)
          }
        )
      end)

    {:noreply, socket}
  end

  @impl true
  def join("cursor:lobby", _payload, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} =
      Presence.track(socket, socket.assigns.current_user, %{
        online_at: inspect(System.system_time(:second)),
        color: PhoenixCursors.Colors.getHSL(socket.assigns.current_user)
      })

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (cursor:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
