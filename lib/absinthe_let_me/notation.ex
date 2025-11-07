defmodule AbsintheLetMe.Notation do
  @moduledoc """
  Provides macros to define policies in Absinthe schema
  """

  defmacro __using__(opts) do
    policy_module = Keyword.get(opts, :policy_module)

    Module.register_attribute(__CALLER__.module, :absinthe_let_me_policy_module, [])
    Module.put_attribute(__CALLER__.module, :absinthe_let_me_policy_module, policy_module)

    quote do
      import unquote(__MODULE__)
    end
  end

  defmacro policy(policy, opts \\ []) do
    policy_module =
      opts[:module] || Module.get_attribute(__CALLER__.module, :absinthe_let_me_policy_module)

    if !policy_module,
      do:
        raise(
          ArgumentError,
          "You must provide :policy_module option when using AbsintheLetMe.Notation"
        )

    quote do
      meta(
        policy: unquote(policy),
        policy_module: unquote(policy_module),
        policy_opts: unquote(opts)
      )
    end
  end

  defmacro policy_object(function_ast) do
    quote do
      meta(policy_object_fun: unquote(function_ast))
    end
  end

  defmacro policy_config(config_fun, opts \\ []) do
    policy = opts[:policy]

    policy_module =
      opts[:policy_module] ||
        Module.get_attribute(__CALLER__.module, :absinthe_let_me_policy_module)

    # Can't fall back to default function here because for subscription config functions
    # there's no source object
    policy_object_fun = opts[:policy_object_fun]

    policy_opts = opts[:policy_opts] || []

    if policy && policy_module && policy_object_fun do
      # If policy is configured, check authorization
      quote do
        config(fn args, resolution ->
          AbsintheLetMe.Policy.policy_config(
            unquote(config_fun),
            unquote(policy),
            unquote(policy_module),
            unquote(policy_object_fun),
            unquote(policy_opts),
            args,
            resolution
          )
        end)
      end
    else
      # No policy configured, call original config directly
      quote do
        config(fn args, resolution ->
          unquote(config_fun).(args, resolution)
        end)
      end
    end
  end
end
