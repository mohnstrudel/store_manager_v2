# frozen_string_literal: true

module User::Notifiable
  extend ActiveSupport::Concern

  def notify(kind:, message:, link: nil)
    NotificationsChannel.broadcast_to(self, {kind: kind.to_s, message:, link:}.compact)
  end
end
