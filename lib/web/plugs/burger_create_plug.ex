defmodule Irateburgers.Web.BurgerCreatePlug do
  @moduledoc """
  Handler plug for POST /burgers
  """

  use Plug.Builder
  import Plug.Conn, only: [put_resp_content_type: 2]
  alias Plug.Conn
  alias Irateburgers.{Burger, BurgerServer, CreateBurger}

  plug :put_resp_content_type, "application/json"
  plug :validate
  plug :authorize
  plug :create
  plug :respond

  def validate(conn, _opts) do
    with {:ok, command = %CreateBurger{}} <- CreateBurger.new(conn.params) do
      Conn.assign conn, :command, command
    else
      {:error, errors} ->
        conn
        |> Conn.send_resp(422, Poison.encode! errors)
        |> Conn.halt()
    end
  end

  def authorize(conn, _opts) do
    conn
  end

  def create(
    conn = %Conn{assigns: %{command: command = %CreateBurger{}}},
    _opts)
  do
    with {:ok, burger = %Burger{}} <- BurgerServer.create(command) do
      Conn.assign conn, :burger, burger
    else
      {:error, :burger_already_exists} ->
        message = "Burger with id: #{command.id} already exists"
        conn
        |> Conn.send_resp(422, Poison.encode! %{error: message})
        |> Conn.halt()

      {:error, reason} ->
        conn
        |> Conn.send_resp(422, Poison.encode! %{error: reason})
        |> Conn.halt()
    end
  end

  def respond(conn = %Conn{assigns: %{burger: burger = %Burger{}}}, _opts) do
    Conn.send_resp(conn, 201, Poison.encode!(burger))
  end
end
