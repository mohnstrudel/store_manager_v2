# frozen_string_literal: true
class ApplicationMailer < ActionMailer::Base
  default from: email_address_with_name("store@handsomecake.com", "HandsomeCake Goodies")
  layout "mailer"
end
