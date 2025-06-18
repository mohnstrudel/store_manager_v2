class PurchaseLinker
  def self.link(arg)
    new(arg).link
  end

  def initialize(purchase)
    raise ArgumentError, "Missing purchase" if purchase.blank?

    @purchase = purchase
    @edition_id = purchase.edition_id
    @product_id = purchase.product_id
    @linked_ids = []
  end

  def link
    return if @purchase.purchase_items.blank?

    unlinked_purchase_items = @purchase.purchase_items.where(sale_item_id: nil).to_a

    SaleItem.linkable_for(@purchase).each do |ps|
      break if unlinked_purchase_items.empty?

      remaining = [
        ps.qty,
        @purchase.amount,
        unlinked_purchase_items.size
      ].min

      unlinked_purchase_items.shift(remaining).each do |pp|
        pp.link_with(ps.id)
        @linked_ids << pp.id
      end
    end

    @linked_ids
  end
end
