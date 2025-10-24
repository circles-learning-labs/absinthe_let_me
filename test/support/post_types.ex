defmodule AbsintheLetMe.Test.Schema.PostTypes do
  use Absinthe.Schema.Notation
  use AbsintheLetMe.Notation, policy_module: AbsintheLetMe.Test.Policy

  object :post do
    field(:id, :integer)
    field(:content, :string)

    field :secret, :string do
      policy(:post_view_secret)
    end

    policy(:post_view)
  end
end
