defmodule AbsintheLetMeTest do
  use ExUnit.Case, async: false
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

    refute Map.has_key?(result, :errors)
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

    assert result.data == %{"post" => %{"content" => "Post content", "id" => 1, "secret" => nil}}
    [error] = result.errors

    assert error.path == ["post", "secret"]
    assert error.message == "Not authorized"
  end

  test "normal user can get secret field on even numbered IDs" do
    result = run_query(@post_query, %{role: :user}, %{"id" => 2})

    assert result.data == %{
             "post" => %{"content" => "Post content", "id" => 2, "secret" => "Top secret"}
           }

    refute Map.has_key?(result, :errors)
  end

  @post_default_object_query """
  query postDefaultObject($id: Int!) {
    postDefaultObject(id: $id) {
      id
      content
      secret
    }
  }
  """
  test "default policy object works" do
    result = run_query(@post_default_object_query, %{role: :user}, %{"id" => 2})

    assert result == %{
             data: %{
               "postDefaultObject" => %{
                 "id" => 2,
                 "content" => "Post content",
                 "secret" => "Top secret"
               }
             }
           }

    refute Map.has_key?(result, :errors)
  end

  test "default policy object works with odd ID" do
    result = run_query(@post_default_object_query, %{role: :user}, %{"id" => 1})

    assert result.data == %{
             "postDefaultObject" => %{
               "id" => 1,
               "content" => "Post content",
               "secret" => nil
             }
           }

    [error] = result.errors
    assert error.path == ["postDefaultObject", "secret"]
    assert error.message == "Not authorized"
  end

  @post_create_mutation """
  mutation postCreate($id: Int!, $content: String!, $secret: String!) {
    postCreate(id: $id, content: $content, secret: $secret) {
      id
      content
      secret
    }
  }
  """
  test "admin can create and retrieve record" do
    result = run_query(@post_create_mutation, %{role: :admin}, input_variables())
    assert result == %{data: %{"postCreate" => input_variables()}}
    refute Map.has_key?(result, :errors)
    assert_received :post_created
  end

  test "user cannot create record" do
    result = run_query(@post_create_mutation, %{role: :user}, input_variables())
    assert result.data == %{"postCreate" => nil}

    [error] = result.errors
    assert error.path == ["postCreate"]
    assert error.message == "Not authorized"
    refute_received :post_created
  end

  test "override default message via config" do
    Application.put_env(:absinthe_let_me, :not_authorized_message, "New not authorized message")
    result = run_query(@post_create_mutation, %{role: :user}, input_variables())
    [error] = result.errors
    assert error.message == "New not authorized message"

    Application.delete_env(:absinthe_let_me, :not_authorized_message)
  end

  defp input_variables do
    %{"id" => 1, "content" => "Content", "secret" => "Secret"}
  end
end
