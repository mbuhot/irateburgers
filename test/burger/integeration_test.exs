defmodule IntegrationTest do
  alias Irateburgers.{
    BurgerReviewed,
    BurgerServer,
    CreateBurger,
    Event,
    Repo,
    TopBurgers
  }

  def run do
    {:ok, cmd} = CreateBurger.new(name: "Big Mac", description: "Meat and cheese", price: "$6.50")
    {:ok, burger} = BurgerServer.create(cmd)
    {:ok, event} = BurgerReviewed.new(
      burger_id: burger.id,
      created_at: DateTime.utc_now(),
      rating: 16,
      review_id: Ecto.UUID.generate(),
      username: "m",
      version: 2)
    Repo.insert!(Event.from_struct(event))
    Process.sleep(500)
    IO.inspect(BurgerServer.get_burger(burger.id))
    IO.inspect(TopBurgers.Server.top_burgers(5))
  end
end
