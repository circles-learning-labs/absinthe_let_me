defmodule AbsintheLetMe.PolicyObject do
  alias AbsintheLetMe.Middleware
  @behaviour Absinthe.Middleware

  def middleware(field, obj) do
    policy_object_fun = field[:meta][:policy_object_fun] || obj[:meta][:policy_object_fun]

    case policy_object_fun do
      nil ->
        []

      code ->
        {term, _binding} = Code.eval_quoted(code)
        [{__MODULE__, {:policy_object_fun, term}}]
    end
  end

  def call(resolution, {:policy_object_fun, policy_object_fun}) do
    case policy_object_fun.(resolution) do
      {:ok, object} ->
        Middleware.stash_object(resolution, object)

      {:error, error} ->
        Middleware.fail_resolution(
          resolution,
          "Failed to retrieve policy object: #{inspect(error)}"
        )
    end
  end

  def default_policy_object_fun do
    case Application.get_env(:absinthe_let_me, :default_policy_object_fun) do
      nil ->
        fn %{source: source} -> {:ok, source} end

      fun when is_function(fun, 1) ->
        fun

      other ->
        raise ArgumentError,
              ":default_policy_object_fun must be a function of arity 1, got: #{inspect(other)}"
    end
  end
end
