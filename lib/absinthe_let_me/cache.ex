defmodule AbsintheLetMe.Cache do
  def get(resolution, policy_module, policy, context, object) do
    cache_key = {policy_module, policy, context, object}

    case get_in(resolution, [Access.key!(:acc), __MODULE__, :cache, cache_key]) do
      nil ->
        :miss

      result ->
        result
    end
  end

  def put(
        %{acc: %{__MODULE__: %{cache: _cache}} = resolution},
        policy_module,
        policy,
        context,
        object,
        result
      ) do
    cache_key = {policy_module, policy, context, object}

    resolution
    |> maybe_init()
    |> put_in([Access.key!(:acc), __MODULE__, :cache, cache_key], result)
  end

  def put(resolution, policy_module, policy, context, object, result) do
    resolution
    |> put_in([Access.key!(:acc), __MODULE__], %{cache: %{}})
    |> put(object, policy_module, policy, context, result)
  end

  defp maybe_init(resolution) do
    case get_in(resolution, [Access.key!(:acc), __MODULE__]) do
      nil -> put_in(resolution, [Access.key!(:acc), __MODULE__], %{cache: %{}})
      _ -> resolution
    end
  end
end
