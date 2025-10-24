defmodule AbsintheLetMe.Test.Helper do
  def run_query(query, context, variables \\ %{}) do
    Absinthe.run!(
      query,
      AbsintheLetMe.Test.Schema,
      context: context,
      variables: variables
    )
  end
end
