defmodule AbsintheLetMe do
  @moduledoc """
  Documentation for `AbsintheLetme`.
  """

  def policy_object(resolution) do
    get_in(resolution, [Access.key!(:acc), AbsintheLetMe.Middleware, :policy_object])
  end
end
