defmodule Irateburgers.Web.BurgerReviewCreatePlug do
  use Plug.Builder
  import Plug.Conn, only: [put_resp_content_type: 2]
  alias Plug.Conn
  alias Irateburgers.{Review, ReviewBurger}
  alias Irateburgers.Web.ErrorHelpers
  alias Ecto.Changeset

  plug :put_resp_content_type, "application/json"
  plug :validate
  plug :authorize
  plug :create
  plug :respond

  def validate(conn, _opts) do
    with {:ok, command = %ReviewBurger{}} <- ReviewBurger.new(conn.params) do
      Conn.assign conn, :command, command
    else
      {:error, changeset = %Changeset{}} ->
        conn
        |> Conn.send_resp(422, Poison.encode! ErrorHelpers.errors_on(changeset))
        |> Conn.halt()
    end
  end

  def authorize(conn, _opts) do
    conn
  end

  def create(conn = %Conn{assigns: %{command: command = %ReviewBurger{}}}, _opts) do
    with {:ok, review = %Review{}} <- Irateburgers.BurgerServer.review_burger(command) do
      Conn.assign conn, :review, review
    else
      {:error, reason} ->
        conn
        |> Conn.send_resp(422, Poison.encode! %{error: reason})
        |> Conn.halt()
    end
  end

  def respond(conn = %Conn{assigns: %{review: review = %Review{}}}, _opts) do
    Conn.send_resp(conn, 201, Poison.encode! Review.serialize(review))
  end
end
