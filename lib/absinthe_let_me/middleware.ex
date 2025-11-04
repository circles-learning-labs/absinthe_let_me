defmodule AbsintheLetMe.Middleware do
  def add_middleware(middleware, %{__private__: field}, %{__private__: obj}) do
    {policy, policy_module} = field[:meta][:policy] || obj[:meta][:policy] || {nil, nil}

    [{__MODULE__, {:policy, policy, policy_module}} | middleware]
  end

  def middleware(middleware, _field, _object) do
    middleware
  end

  def call(resolution, {:policy, nil, nil}) do
    resolution
  end

  def call(resolution, {:policy_object_fun, policy_object_fun}) do
    case policy_object_fun.(resolution.arguments, resolution.context) do
      {:ok, object} ->
        stash_object(resolution, object)

      _ ->
        resolution
    end
  end

  def call(resolution, {:policy, policy_module, policy}) do
    object = AbsintheLetMe.policy_object(resolution)
    if is_nil(object) do
      IO.inspect resolution
    end

    case policy_module.authorize(policy, resolution.context, object) do
      :ok ->
        resolution

      _error ->
        not_authorized(resolution)
    end
  end

  defp not_authorized(resolution, message \\ "Not authorized") do
    Absinthe.Resolution.put_result(resolution, {:error, message})
  end

  defp stash_object(%{acc: %{__MODULE__ => _}} = resolution, object) do
    put_in(resolution, [Access.key!(:acc), __MODULE__, :policy_object], object)
  end

  defp stash_object(resolution, object) do
    resolution
    |> put_in([Access.key!(:acc), __MODULE__], %{})
    |> stash_object(object)
  end
end
