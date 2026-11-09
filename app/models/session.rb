# frozen_string_literal: true

# == Schema Information
#
# Table name: sessions
#
#  id         :bigint           not null, primary key
#  ip_address :string
#  user_agent :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
class Session < ApplicationRecord
  db_belongs_to :user, inverse_of: :sessions

  def self.staff_request?(request)
    user = find_by(id: request.cookie_jar.signed[:session_id])&.user
    user.present? && !user.guest?
  end
end
