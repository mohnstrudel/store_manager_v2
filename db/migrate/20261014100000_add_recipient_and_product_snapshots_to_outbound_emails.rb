# frozen_string_literal: true

class AddRecipientAndProductSnapshotsToOutboundEmails < ActiveRecord::Migration[8.1]
  def change
    change_table :outbound_emails, bulk: true do |table|
      table.string :recipient_name
      table.text :product_title
    end
  end
end
