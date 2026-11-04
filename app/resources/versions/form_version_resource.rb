# frozen_string_literal: true

class Versions::FormVersionResource < VersionResource
  typelize :number, nullable: true
  attribute :id, &:id

  typelize :string, nullable: true
  attribute :created_at do |version|
    formatted_timestamp(version.created_at)
  end

  typelize :string, nullable: true
  attribute :updated_at do |version|
    formatted_timestamp(version.updated_at)
  end
end
