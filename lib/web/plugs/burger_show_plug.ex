defmodule Irateburgers.Web.BurgerShowPlug do
  use Plug.Builder
  import Plug.Conn, only: [put_resp_content_type: 2]
  alias Plug.Conn

  plug :put_resp_content_type, "application/json"
  plug :validate
  plug :authorize
  plug :create
  plug :respond

  def validate(conn, _opts) do
    conn
  end

  def authorize(conn, _opts) do
    conn
  end

  def create(conn, _opts) do
    conn
  end

  def respond(conn, _opts) do
    Conn.send_resp(conn, 200, ~S({"burger": "Big Mac"}))
  end
end
