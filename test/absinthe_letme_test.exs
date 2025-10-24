defmodule AbsintheLetMeTest do
  use ExUnit.Case
  import AbsintheLetMe.Test.Helper

  @minimal_post_query """
  query post($id: Int!) {
    post(id: $id) {
      id
      content
    }
  }
  """
  test "normal user can get all public fields" do
    result = run_query(@minimal_post_query, %{role: :user}, %{"id" => 1})

    assert result == %{
             data: %{
               "post" => %{
                 "id" => 1,
                 "content" => "Post content"
               }
             }
           }
  end

  @post_query """
  query post($id: Int!) {
    post(id: $id) {
      id
      content
      secret
    }
  }
  """
  test "normal user cannot get secret field on odd numbered IDs" do
    result = run_query(@post_query, %{role: :user}, %{"id" => 1})

    assert result.data == %{"post" => %{"content" => "Post content", "id" => 1, "secret" => nil}},
    [error] = result.errors
    assert error.path == ["post", "secret"]
    assert error.message == "Not authorized"
  end

  test "normal user can get secret field on even numbered IDs" do
    result = run_query(@post_query, %{role: :user}, %{"id" => 2})
    IO.inspect result

#    assert result.data == %{"post" => %{"content" => "Post content", "id" => 1, "secret" => "Top secret"}},
#    result.errors
  end
end
