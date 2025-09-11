class SaleFinder
  def self.find(order_identifier, customer_identifier = nil)
    new(order_identifier, customer_identifier).find
  end

  def initialize(order_identifier, customer_identifier = nil)
    raise ArgumentError, "order_identifier cannot be blank" if order_identifier.blank?

    @order_identifier = order_identifier
    @customer_identifier = customer_identifier
  end

  def find
    shopify_sale = find_shopify_sale
    woo_sale = find_woo_sale

    return shopify_sale || woo_sale unless shopify_sale.present? && woo_sale.present?

    customer = find_customer
    select_appropriate_sale(customer, shopify_sale, woo_sale)
  end

  private

  def find_shopify_sale
    shopify_name = if @order_identifier.upcase.include?("HSCM#")
      @order_identifier.upcase
    else
      "HSCM##{@order_identifier}"
    end
    Sale.find_by(shopify_name:)
  end

  def find_woo_sale
    Sale.find_by(woo_id: @order_identifier.gsub("HSCM#", ""))
  end

  def find_customer
    return nil if @customer_identifier.blank?

    customer = Customer.find_by(id: @customer_identifier)
    customer ||= Customer.find_by(email: @customer_identifier)
    customer
  end

  def select_appropriate_sale(customer, shopify_sale, woo_sale)
    if customer.present?
      select_sale_for_customer(customer, shopify_sale, woo_sale)
    else
      choose_sale_by_status_and_recency(shopify_sale, woo_sale)
    end
  end

  def select_sale_for_customer(customer, shopify_sale, woo_sale)
    customer_sales = customer.sales.where(id: [shopify_sale.id, woo_sale.id])

    if customer_sales.count >= 2
      select_active_or_newer_sale(customer_sales)
    elsif customer_sales.one?
      customer_sales.first
    else
      choose_sale_by_status_and_recency(shopify_sale, woo_sale)
    end
  end

  def select_active_or_newer_sale(sales)
    active_sales = sales.select(&:active?)

    if active_sales.any?
      active_sales.max_by(&:shop_created_at)
    else
      sales.max_by(&:shop_created_at)
    end
  end

  def choose_sale_by_status_and_recency(shopify_sale, woo_sale)
    if shopify_sale.active? && woo_sale.active?
      [shopify_sale, woo_sale].max_by(&:shop_created_at)
    elsif shopify_sale.active?
      shopify_sale
    elsif woo_sale.active?
      woo_sale
    else
      [shopify_sale, woo_sale].max_by(&:shop_created_at)
    end
  end
end
