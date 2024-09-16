class SendWelcomeEmailJob < ApplicationJob
  queue_as :default

  CLIENT = MailchimpTransactional::Client.new(ENV["MAIL_API_KEY"])

  def perform(email, subject, text)
    message = {
      from_email: "store@handsomecake.com",
      subject:,
      text:,
      to: [
        {
          email:,
          type: "to"
        }
      ]
    }
    begin
      CLIENT.messages.send(message:)
    rescue MailchimpTransactional::ApiError => e
      warn "Error: #{e}"
    end
  end

  # We can have editable regions "mc:edit" in our templates, e.g.:
  #   <div mc:edit="header">
  #     <h2>Thank you for your purchase</h2>
  #   </div>
  # We can replace content inside them using the "template_content":
  #   template_content: [{
  #     name: "header",
  #     content: "<h2>Your Order is Complete</h2>"
  #   }]
  # Another option is to use variables and conditional logic: https://mailchimp.com/developer/transactional/docs/templates-dynamic-content/#mailchimp-merge-language
  def generate_template(template_name, email_vars)
    merge_vars = email_vars.map do |key, value|
      {name: key, content: value}
    end
    result =
      CLIENT.templates.render(
        {
          template_name:,
          merge_vars:
        }
      )
    p result
  rescue MailchimpTransactional::ApiError => e
    puts "Error: #{e}"
  end
end
