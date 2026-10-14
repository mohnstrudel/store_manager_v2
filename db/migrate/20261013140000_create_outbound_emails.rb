# frozen_string_literal: true

class CreateOutboundEmails < ActiveRecord::Migration[8.1]
  def change
    create_table :outbound_emails do |t|
      t.string :source, null: false
      t.string :mail_kind
      t.bigint :purchase_item_id, null: false
      t.bigint :sale_item_id, null: false
      t.bigint :warehouse_id, null: false
      t.string :recipient
      t.string :sender
      t.string :subject
      t.text :body
      t.string :state, null: false, default: "pending"
      t.integer :attempts, null: false, default: 0
      t.datetime :last_attempt_at
      t.string :last_error
      t.datetime :accepted_at
      t.datetime :created_at, null: false
    end

    add_index :outbound_emails, :purchase_item_id
    add_index :outbound_emails, :sale_item_id
    add_index :outbound_emails, :id, where: "state = 'pending'", name: "index_outbound_emails_on_id_where_pending"

    add_check_constraint :outbound_emails,
      "source IN ('link', 'warehouse_move', 'explicit_resend', 'baseline')",
      name: "outbound_emails_source_allowed_values"
    add_check_constraint :outbound_emails,
      "state IN ('pending', 'accepted', 'simulated', 'assumed_baseline')",
      name: "outbound_emails_state_allowed_values"
    add_check_constraint :outbound_emails,
      "mail_kind IS NULL OR mail_kind IN ('order_status_updated', 'order_status_changed')",
      name: "outbound_emails_mail_kind_allowed_values"
    add_check_constraint :outbound_emails,
      "(state = 'assumed_baseline' AND source = 'baseline' AND mail_kind IS NULL AND recipient IS NULL " \
      "AND sender IS NULL AND subject IS NULL AND body IS NULL AND attempts = 0 " \
      "AND last_attempt_at IS NULL AND last_error IS NULL AND accepted_at IS NULL) OR " \
      "(state <> 'assumed_baseline' AND source <> 'baseline' AND mail_kind IS NOT NULL AND recipient IS NOT NULL " \
      "AND sender IS NOT NULL AND subject IS NOT NULL AND body IS NOT NULL)",
      name: "outbound_emails_baseline_or_message"
    add_check_constraint :outbound_emails,
      "(state = 'accepted') = (accepted_at IS NOT NULL)",
      name: "outbound_emails_accepted_at_only_when_accepted"
  end
end
