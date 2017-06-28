defmodule Irateburgers.Web.BurgerCreatePlugTest do
  use Irateburgers.Web.ConnCase
  alias Plug.Conn

  describe "Creating a burger" do
    test "Succeeds with valid params", %{conn: conn} do
      params = Poison.encode! %{
        name: "Big Mac",
        price: "$6.50",
        description: "Beef, Cheese, Lettuce, Pickles, Special Sauce",
        images: ["http://imgur.com/foo/bar"]
      }

      response =
        conn
        |> Conn.put_req_header("content-type", "application/json")
        |> post(burger_path(conn, :create), params)
        |> json_response(201)

      assert %{
        "description" => "Beef, Cheese, Lettuce, Pickles, Special Sauce",
        "id" => id,
        "images" => ["http://imgur.com/foo/bar"],
        "name" => "Big Mac",
        "price" => "$6.50",
        "reviews" => []
      } = response
      assert id != nil
    end

    test "fails with missing fields", %{conn: conn} do
      response =
        conn
        |> Conn.put_req_header("content-type", "application/json")
        |> post(burger_path(conn, :create), "{}")
        |> json_response(422)

      assert %{
        "price" => ["can't be blank"],
        "name" => ["can't be blank"],
        "description" => ["can't be blank"]
      } = response
    end
  end
end
