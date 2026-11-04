# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationJob do
  include ActiveJob::TestHelper

  it "discards a job whose record argument was deleted" do
    product = create(:product)
    Shopify::ImportMediaJob.perform_later(product, [])
    product.destroy!

    expect { perform_enqueued_jobs }.not_to raise_error
    expect(enqueued_jobs).to be_empty
  end
end
