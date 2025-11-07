defmodule AbsintheLetMe.Middleware do
  @moduledoc """
  Middleware to enforce authorization policies in Absinthe GraphQL.
  """

  alias AbsintheLetMe.Policy
  alias AbsintheLetMe.PolicyObject

  def add_middleware(
        middleware,
        %{__private__: field} = _a,
        %{
          identifier: identifier,
          __private__: obj
        } = _b
      ) do
    policy_middleware = Policy.middleware(field, obj)
    policy_object_middleware = PolicyObject.middleware(field, obj)

    case get_location(identifier) do
      :start -> policy_object_middleware ++ policy_middleware ++ middleware
      :end -> middleware ++ policy_object_middleware ++ policy_middleware
    end
  end

  def add_middleware(middleware, _field, _object) do
    middleware
  end

  def get_object(%{acc: %{__MODULE__ => %{policy_object: object}}}) do
    object
  end

  def get_object(_resolution) do
    nil
  end

  def stash_object(%{acc: %{__MODULE__ => _}} = resolution, object) do
    put_in(resolution, [Access.key!(:acc), __MODULE__, :policy_object], object)
  end

  def stash_object(resolution, object) do
    resolution
    |> put_in([Access.key!(:acc), __MODULE__], %{})
    |> stash_object(object)
  end

  defp get_location(:mutation), do: :start
  defp get_location(:query), do: :start
  defp get_location(_), do: :end

  def fail_resolution(resolution, message) do
    Absinthe.Resolution.put_result(resolution, {:error, message})
  end
end
