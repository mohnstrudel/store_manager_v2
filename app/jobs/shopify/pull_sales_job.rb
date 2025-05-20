class Shopify::PullSalesJob < Shopify::BasePullJob
  private

  def resource_name
    "orders"
  end

  def parser_class
    Shopify::SaleParser
  end

  def creator_class
    Shopify::SaleCreator
  end

  def batch_size
    250
  end
end
