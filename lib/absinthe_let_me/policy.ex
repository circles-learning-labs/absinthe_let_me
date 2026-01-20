defmodule AbsintheLetMe.Policy do
  alias AbsintheLetMe.Middleware
  alias AbsintheLetMe.PolicyObject
  @behaviour Absinthe.Middleware

  def middleware(field, obj) do
    policy = field[:meta][:policy] || obj[:meta][:policy]
    policy_module = field[:meta][:policy_module] || obj[:meta][:policy_module]
    opts = field[:meta][:policy_opts] || obj[:meta][:policy_opts] || []

    if policy && policy_module do
      [{__MODULE__, {:policy, policy, policy_module, opts}}]
    else
      []
    end
  end

  def call(resolution, {:policy, policy, policy_module, opts}) do
    {new_resolution, object} = policy_object(resolution)

    case policy_module.authorize(policy, resolution.context, object) do
      :ok ->
        new_resolution

      {:error, :unauthorized} ->
        not_authorized(resolution, opts)
    end
  end

  defp not_authorized(resolution, opts) do
    Middleware.fail_resolution(resolution, not_authorized_message(opts))
  end

  @doc """
  Returns the not authorized message based on opts and application config.
  """
  def not_authorized_message(opts) do
    opts[:not_authorized_message] ||
      Application.get_env(:absinthe_let_me, :not_authorized_message) || "Not authorized"
  end

  def policy_object(resolution) do
    case Middleware.get_object(resolution) do
      nil ->
        case PolicyObject.default_policy_object_fun().(resolution) do
          {:ok, object} ->
            resolution
            |> Middleware.stash_object(object)
            |> policy_object()

          {:error, error} ->
            Middleware.fail_resolution(
              resolution,
              "Failed to retrieve default policy object: #{inspect(error)}"
            )
        end

      object ->
        {resolution, object}
    end
  end

  def policy_config(
        config_fun,
        policy,
        policy_module,
        policy_object_fun,
        policy_opts,
        args,
        resolution
      ) do
    resolution_with_args = resolution |> Map.put(:arguments, args)

    with {:ok, policy_object} <-
           policy_object_fun.(resolution_with_args),
         :ok <-
           policy_module.authorize(
             policy,
             resolution.context,
             policy_object
           ) do
      # Authorization passed, call original config
      config_fun.(args, resolution)
    else
      {:error, :unauthorized} ->
        {:error, AbsintheLetMe.Policy.not_authorized_message(policy_opts)}

      {:error, message} ->
        {:error, message}
    end
  end
end
