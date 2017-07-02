defmodule Irateburgers.Web.BurgerReviewCreatePlugTest do
  use Irateburgers.Web.ConnCase
  alias Plug.Conn
  alias Irateburgers.{BurgerCreated, Repo}

  describe "Reviewing a Burger" do
    setup %{conn: conn} do
      id = Ecto.UUID.generate()
      {:ok, event} = BurgerCreated.new(burger_id: id, version: 1, name: "Whopper", price: "$4.95", description: "huge")
      Repo.insert!(BurgerCreated.to_eventlog(event))

      conn = Conn.put_req_header(conn, "content-type", "application/json")
      %{conn: conn, burger_id: id}
    end

    test "Succeeds with valid parameters", %{conn: conn, burger_id: id} do
      review_params = Poison.encode! %{
        username: "Flipper",
        rating: 3,
        comment: "Best, ever"
      }

      response =
        conn
        |> post(burger_review_path(conn, :create, id), review_params)
        |> json_response(201)

      assert %{
        "comment" => "Best, ever",
        "created_at" => _,
        "id" => _,
        "rating" => 3,
        "username" => "Flipper"
      } = response
    end

    test "fails with missing fields", %{conn: conn, burger_id: id} do
      response =
        conn
        |> post(burger_review_path(conn, :create, id), %{})
        |> json_response(422)

      assert response == %{
        "username" => ["can't be blank"],
        "rating" => ["can't be blank"],
        "comment" => ["can't be blank"],
      }
    end

    test "fails if burger doesn't exist", %{conn: conn} do
      id = Ecto.UUID.generate()

      review_params = Poison.encode! %{
        username: "Flipper",
        rating: 3,
        comment: "Best, ever"
      }

      response =
        conn
        |> post(burger_review_path(conn, :create, id), review_params)
        |> json_response(404)

      assert response == %{"error" => "Burger with id: #{id} not found"}
    end
  end
end
