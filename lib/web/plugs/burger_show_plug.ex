defmodule Irateburgers.Web.BurgerShowPlug do
  @moduledoc """
  Handler plug for get /burgers/:id
  """

  use Plug.Builder
  import Plug.Conn, only: [put_resp_content_type: 2]
  alias Plug.Conn

  plug :put_resp_content_type, "application/json"
  plug :validate
  plug :authorize
  plug :create
  plug :respond

  @spec validate(Conn.t, []) :: Conn.t
  def validate(conn, _opts) do
    conn
  end

  @spec authorize(Conn.t, []) :: Conn.t
  def authorize(conn, _opts) do
    conn
  end

  @spec create(Conn.t, []) :: Conn.t
  def create(conn, _opts) do
    conn
  end

  @spec respond(Conn.t, []) :: Conn.t
  def respond(conn, _opts) do
    Conn.send_resp(conn, 200, ~S({"burger": "Big Mac"}))
  end
end
