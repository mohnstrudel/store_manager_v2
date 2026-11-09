# frozen_string_literal: true

class SharedPropsResource < ApplicationResource
  FLASH_MESSAGE = "string | { message: string; link?: { label: string; href: string; suffix?: string } } | null"

  typelize :string, nullable: true
  attribute :breadcrumb do |shared|
    shared.fetch(:breadcrumb)
  end

  typelize :string
  attribute :environment do |_shared|
    Rails.env.to_s
  end

  typelize({user: "CurrentUser | null"})
  attribute :auth do |shared|
    user = shared.fetch(:user)
    {user: user && CurrentUserResource.new(user).serializable_hash}
  end

  typelize({notice: FLASH_MESSAGE, alert: FLASH_MESSAGE})
  attribute :flash do |shared|
    flash = shared.fetch(:flash)
    {notice: flash.notice, alert: flash.alert}
  end

  typelize :string
  attribute :csrf_token do |shared|
    shared.fetch(:csrf_token)
  end
end
