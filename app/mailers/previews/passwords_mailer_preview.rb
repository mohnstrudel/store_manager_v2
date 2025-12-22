# frozen_string_literal: true
# Preview at http://localhost:3000/rails/mailers/passwords_mailer
class PasswordsMailerPreview < ActionMailer::Preview
  def reset
    # Rails.application.routes.default_url_options[:host] = "localhost:3000"
    PasswordsMailer.reset(User.take)
  end
end
