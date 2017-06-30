defmodule Irateburgers.Web.BurgerCreatePlugTest do
  use Irateburgers.Web.ConnCase
  alias Plug.Conn

  def big_mac_params do
    %{
      name: "Big Mac",
      price: "$6.50",
      description: "Beef, Cheese, Lettuce, Pickles, Special Sauce",
      images: ["http://imgur.com/foo/bar"]
    }
  end

  describe "Creating a burger" do
    setup %{conn: conn} do
      %{conn: Conn.put_req_header(conn, "content-type", "application/json")}
    end

    test "Succeeds with valid params", %{conn: conn} do
      response =
        conn
        |> post(burger_path(conn, :create), Poison.encode!(big_mac_params()))
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
