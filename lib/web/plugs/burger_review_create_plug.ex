defmodule Irateburgers.Web.BurgerReviewCreatePlug do
  @moduledoc """
  Handler plug for post /burgers/:id/reviews
  """

  use Plug.Builder
  import Plug.Conn, only: [put_resp_content_type: 2]
  alias Plug.Conn
  alias Irateburgers.{Burger, BurgerServer, Review, ReviewBurger}

  plug :put_resp_content_type, "application/json"
  plug :validate
  plug :authorize
  plug :create
  plug :respond

  @spec validate(Conn.t, []) :: Conn.t
  def validate(conn, _opts) do
    params = Map.put(conn.params, "burger_id", conn.params["id"])
    with {:ok, command = %ReviewBurger{}} <- ReviewBurger.new(params) do
      Conn.assign conn, :command, command
    else
      {:error, errors} ->
        conn
        |> Conn.send_resp(422, Poison.encode! errors)
        |> Conn.halt()
    end
  end

  @spec authorize(Conn.t, []) :: Conn.t
  def authorize(conn, _opts) do
    conn
  end

  @spec create(Conn.t, []) :: Conn.t
  def create(
    conn = %Conn{assigns: %{command: command = %ReviewBurger{}}}, _opts) do

    with {:ok, burger = %Burger{}} <- BurgerServer.review_burger(command),
         review <- Burger.find_review_by_user(burger, command.username) do
      Conn.assign conn, :review, review
    else
      {:error, :burger_not_found} ->
        message = "Burger with id: #{command.burger_id} not found"
        conn
        |> Conn.send_resp(404, Poison.encode! %{error: message})
        |> Conn.halt()
      {:error, reason} ->
        conn
        |> Conn.send_resp(422, Poison.encode! %{error: reason})
        |> Conn.halt()
    end
  end

  @spec respond(Conn.t, []) :: Conn.t
  def respond(conn = %Conn{assigns: %{review: review = %Review{}}}, _opts) do
    Conn.send_resp(conn, 201, Poison.encode!(review))
  end
end
