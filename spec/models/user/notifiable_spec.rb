# frozen_string_literal: true

require "rails_helper"

RSpec.describe User::Notifiable do
  let(:user) { create(:user) }

  it "broadcasts the notification to the user's notifications stream" do
    link = {label: "Open broken sales", href: "/broken_sales"}

    expect { user.notify(kind: :alert, message: "Some orders could not be pulled.", link:) }
      .to have_broadcasted_to(user).from_channel(NotificationsChannel)
      .with(kind: "alert", message: "Some orders could not be pulled.", link:)
  end

  it "leaves out a missing link" do
    expect { user.notify(kind: :notice, message: "Done.") }
      .to have_broadcasted_to(user).from_channel(NotificationsChannel).with(kind: "notice", message: "Done.")
  end
end
