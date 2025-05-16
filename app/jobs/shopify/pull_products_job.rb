class Shopify::PullProductsJob < Shopify::BasePullJob
  private

  def resource_name
    "products"
  end

  def parser_class
    Shopify::ProductParser
  end

  def creator_class
    Shopify::ProductCreator
  end

  def batch_size
    250
  end
end
