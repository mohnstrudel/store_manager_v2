class RemoveEmailTemplateFromNotifications < ActiveRecord::Migration[8.0]
  def up
    remove_reference :notifications, :email_template, foreign_key: true
  end

  def down
    add_reference :notifications, :email_template, null: false, foreign_key: true # rubocop:todo Rails/NotNullColumn
  end
end
