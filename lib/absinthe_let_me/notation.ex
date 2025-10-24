defmodule AbsintheLetMe.Notation do
  defmacro __using__(opts) do
    policy_module =
      Keyword.get(opts, :policy_module) ||
        raise ArgumentError,
              "You must provide :policy_module option when using AbsintheLetMe.Notation"

    Module.register_attribute(__CALLER__.module, :policy_module, [])
    Module.put_attribute(__CALLER__.module, :policy_module, policy_module)

    quote do
      import unquote(__MODULE__)
    end
  end

  defmacro policy(policy) do
    policy_module = Module.get_attribute(__CALLER__.module, :policy_module)
    quote do
      meta(:policy, {unquote(policy_module), unquote(policy)})
    end
  end

  defmacro policy_object(policy_object_fun) do
    quote do
      meta(:policy_object, policy_object_fun)
    end
  end
end
