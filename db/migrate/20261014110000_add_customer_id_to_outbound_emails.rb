# frozen_string_literal: true

class AddCustomerIdToOutboundEmails < ActiveRecord::Migration[8.1]
  def up
    add_column :outbound_emails, :customer_id, :bigint

    execute <<~SQL.squish
      UPDATE outbound_emails AS email
      SET customer_id = sale.customer_id
      FROM sale_items AS sale_item
      JOIN sales AS sale ON sale.id = sale_item.sale_id
      JOIN customers AS customer ON customer.id = sale.customer_id
      WHERE email.sale_item_id = sale_item.id
        AND email.recipient = customer.email
        AND email.source <> 'baseline'
    SQL
  end

  def down
    remove_column :outbound_emails, :customer_id
  end
end
