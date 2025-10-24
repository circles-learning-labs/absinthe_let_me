defmodule AbsintheLetMe.Test.Schema do
  use Absinthe.Schema
  use AbsintheLetMe.Notation, policy_module: AbsintheLetMe.Test.Policies

  import_types(AbsintheLetMe.Test.Schema.PostTypes)

  query do
    field :post, :post do
      arg(:id, non_null(:integer))

      resolve(fn _, %{id: id}, _ ->
        post(id)
      end)

      policy_object(fn _, %{id: id}, _ -> post(id) end)
    end
  end

  mutation do
    field :post_create, :post do
      arg(:content, non_null(:string))

      resolve(fn _, %{content: content}, _ ->
        {:ok, %{id: 1, content: content, secret: "New post secret"}}
      end)

      #  policy(:post_create)
    end
  end

  def post(id) do
    {:ok, %{id: id, content: "Post content", secret: "Top secret"}}
  end

  def middleware(middleware, field, object) do
    AbsintheLetMe.Middleware.add_middleware(middleware, field, object)
  end
end
