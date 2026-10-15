# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OutboundEmails" do
  before { sign_in_as_admin }

  describe "GET /outbound_emails" do
    it "shows newest records first, paginates, and excludes message bodies from list props" do
      oldest = create(:outbound_email, body: "Private old message")
      middle = create_list(:outbound_email, 10) + create_list(:outbound_email, 10) + create_list(:outbound_email, 5)
      newest = create(:outbound_email, recipient_name: "John Doe", product_title: "Blue Statue")
      create(:outbound_email, :assumed_baseline)

      get outbound_emails_path

      expect_inertia.to render_component("OutboundEmails/Index")
      expect(inertia.props[:outbound_emails].first).to include(
        id: newest.id, recipient_name: "John Doe", product_title: "Blue Statue",
        subject: newest.subject, state: "pending"
      )
      expect(inertia.props[:outbound_emails].size).to eq(25)
      expect(inertia.props[:outbound_emails].first).not_to have_key(:body)
      expect(inertia.props[:outbound_emails].first).to include(
        customer_path: nil, sale_path: nil, purchase_path: nil
      )
      expect(inertia.props[:pagination]).to include(total_count: 27, total_pages: 2, limit: 25)

      get outbound_emails_path, params: {page: 2}

      expect(inertia.props[:outbound_emails].pluck(:id)).to eq([middle.first.id, oldest.id])
    end

    it "searches recipient, name, product, subject, and saved body" do
      recipient = create(:outbound_email, recipient: "unique-buyer@example.com")
      name = create(:outbound_email, recipient_name: "Vasily Kupkin")
      product = create(:outbound_email, product_title: "Golden Figurine")
      subject = create(:outbound_email, subject: "Distinctive shipment subject")
      body = create(:outbound_email, body: "The package is in Moonbase storage")

      {"unique-buyer@example.com" => recipient, "Vasily Kupkin" => name, "Figurine" => product,
       "Distinctive" => subject, "Moonbase" => body}.each do |query, expected|
        get outbound_emails_path, params: {q: query}

        expect(inertia.props[:outbound_emails].pluck(:id)).to eq([expected.id])
        expect(inertia.props[:search]).to eq("q" => query)
      end
    end

    it "shows the current product photo alongside the saved product title" do
      product = create(:product)
      create(:media, :for_product, mediaable: product)
      sale_item = create(:sale_item, product:)
      email = create(:outbound_email, sale_item_id: sale_item.id, product_title: "Original Figurine")

      get outbound_emails_path

      expect(inertia.props[:outbound_emails].sole).to include(
        id: email.id, product_title: "Original Figurine"
      )
      expect(inertia.props[:outbound_emails].sole[:product_thumb_url]).to be_present
    end

    it "links the customer and the sale and purchase recorded for the email" do
      sale_item = create(:sale_item)
      sale_item.sale.update!(shopify_name: "SHOP#1746")
      purchase_item = create(:purchase_item)
      customer = sale_item.sale.customer
      email = create(:outbound_email, sale_item_id: sale_item.id, purchase_item_id: purchase_item.id,
        customer_id: customer.id)
      sale_item.sale.update!(customer: create(:customer))

      get outbound_emails_path

      expect(inertia.props[:outbound_emails].sole).to include(
        id: email.id,
        customer_path: customer_path(customer),
        sale_path: sale_path(sale_item.sale),
        sale_label: "Sale SHOP#1746",
        purchase_path: purchase_path(purchase_item.purchase),
        purchase_label: "Purchase #{purchase_item.purchase.id}"
      )
    end

    it "allows managers and denies support staff" do
      log_out
      sign_in create(:user, :manager)

      get outbound_emails_path
      expect(response).to have_http_status(:ok)

      log_out
      sign_in create(:user, :support)

      get outbound_emails_path
      expect(response).to redirect_to(noop_path)
    end
  end

  describe "GET /outbound_emails/:id" do
    it "shows the stored snapshot and delivery details" do
      email = create(:outbound_email, state: "accepted", accepted_at: Time.current,
        body: "Hello buyer\nYour order moved", attempts: 1, last_attempt_at: Time.current,
        recipient_name: "John Doe", product_title: "Blue Statue")

      get outbound_email_path(email)

      expect_inertia.to render_component("OutboundEmails/Show")
      expect(inertia.props[:outbound_email]).to include(
        id: email.id, recipient: email.recipient, recipient_name: "John Doe",
        product_title: "Blue Statue", subject: email.subject,
        body: "Hello buyer\nYour order moved", state: "accepted", attempts: 1
      )
    end

    it "does not expose a baseline record as an email" do
      baseline = create(:outbound_email, :assumed_baseline)

      get outbound_email_path(baseline)

      expect(response).to have_http_status(:not_found)
    end

    it "allows managers and denies support staff" do
      email = create(:outbound_email)
      log_out
      sign_in create(:user, :manager)

      get outbound_email_path(email)
      expect(response).to have_http_status(:ok)

      log_out
      sign_in create(:user, :support)

      get outbound_email_path(email)
      expect(response).to redirect_to(noop_path)
    end
  end
end
