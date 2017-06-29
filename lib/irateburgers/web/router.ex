defmodule Irateburgers.Web.Router do
  use Irateburgers.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api/v1", Irateburgers.Web do
    pipe_through :api

    post "/burgers", BurgerCreatePlug, :create, as: :burger
    get  "/burgers/:id", BurgerShowPlug, :show, as: :burger
    post "/burgers/:id/reviews", BurgerReviewCreatePlug, :create, as: :burger_review
  end
end
