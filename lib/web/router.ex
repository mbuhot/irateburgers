defmodule Irateburgers.Web.Router do
  use Phoenix.Router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api/v1", Irateburgers.Web do
    pipe_through :api

    scope "/burgers" do
      post "/", BurgerCreatePlug, :create, as: :burger
      get  "/:id", BurgerShowPlug, :show, as: :burger
      post "/:id/reviews", BurgerReviewCreatePlug, :create, as: :burger_review
    end
  end
end
