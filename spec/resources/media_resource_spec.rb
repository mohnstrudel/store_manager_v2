# frozen_string_literal: true

require "rails_helper"

RSpec.describe MediaResource do
  it "serializes only attached media with representation paths" do
    warehouse = create(:warehouse)
    media = create(:media, :for_warehouse, mediaable: warehouse)
    detached = create(:media, :for_warehouse, mediaable: warehouse)
    detached.image.purge

    props = described_class.attached(warehouse.media.reload).map(&:deep_symbolize_keys)

    expect(props.pluck(:id)).to eq([media.id])
    expect(props.first[:preview_url]).to start_with("/rails/active_storage/")
    expect(props.first[:thumb_url]).to start_with("/rails/active_storage/")
  end
end
