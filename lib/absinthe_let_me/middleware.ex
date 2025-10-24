defmodule AbsintheLetMe.Middleware do
  def add_middleware(middleware, %{__private__: field}, %{__private__: obj}, opts \\ []) do
    policy = field[:meta][:policy] || obj[:meta][:policy]
    policy_object_fun = field[:meta][:policy_object] || obj[:meta][:policy_object]
    IO.inspect policy_object_fun, label: :policy_object_fun_in_middleware

    [{__MODULE__, {policy, policy_object_fun, opts}} | middleware]
  end

  def middleware(middleware, _field, _object) do
    middleware
  end

  def call(resolution, {nil, nil, _opts}) do
    resolution
  end

  def call(resolution, {nil, policy_object_fun, _opts}) do
    case get_object(policy_object_fun, resolution) do
      {:ok, object} ->
        stash_object(resolution, object)

      _ ->
        resolution
    end
  end

  def call(resolution, {{policy_module, policy}, policy_object_fun, _opts}) do
    object_result =
      case policy_object_fun do
        nil -> nil
        fun -> fun.(resolution.parent, resolution.arguments, resolution.context)
      end

    case object_result do
      {:ok, object} ->
        case policy_module.authorize(policy, resolution.context, object) do
          :ok ->
            stash_object(resolution, object)

          _error ->
            not_authorized(resolution)
        end

      _ ->
        not_authorized(resolution, "No policy_object specified")
    end
  end

  defp not_authorized(resolution, message \\ "Not authorized") do
    Absinthe.Resolution.put_result(resolution, {:error, message})
  end

  defp get_object(policy_object_fun, resoultion) do
    policy_object_fun.(nil, resoultion.arguments, resoultion.context)
  end

  defp stash_object(resolution, object) do
    put_in(resolution, [:acc, __MODULE__, :policy_object], object)
  end
end
