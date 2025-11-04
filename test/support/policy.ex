defmodule AbsintheLetMe.Test.Policy do
  use LetMe.Policy, check_module: __MODULE__

  object :post do
    action :view do
      allow(:all)
    end

    action :view_secret do
      allow(:id_is_even)
      allow(:admin)
    end

    action :create do
      allow(role_in: [:editor, :admin])
    end
  end

  def all(_subject, _object) do
    true
  end

  def admin(subject, _object) do
    subject.role == :admin
  end

  def role_in(subject, _object, roles) do
    subject.role in roles
  end

  def id_is_even(_subject, object) do
    rem(object.id, 2) == 0
  end
end
