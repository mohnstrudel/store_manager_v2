# frozen_string_literal: true

class MediaUploadPolicy < ApplicationPolicy
  def create?
    admin? || manager?
  end
end
