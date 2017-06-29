defmodule Irateburgers.Web.BurgerReviewCreatePlugTest do
  use Irateburgers.Web.ConnCase
  alias Plug.Conn
  alias Irateburgers.{BurgerCreated, Repo}

  describe "Reviewing a Burger" do
    test "Succeeds with valid parameters", %{conn: conn} do
      id = Ecto.UUID.generate()
      event = %BurgerCreated{id: id, version: 1, name: "Whopper", price: "$4.95", description: "", images: []}
      Repo.insert!(BurgerCreated.to_eventlog(event))

      review_params = %{
        burger_id: id,
        username: "Flipper",
        rating: 3,
        comment: "Best, ever"
      }

      response =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(burger_review_path(conn, :create, id), review_params)
        |> json_response(201)

      assert response == %{}
    end

    # test "fails with missing fields", %{conn: conn} do
    # end
  end
end
