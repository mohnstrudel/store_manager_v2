# frozen_string_literal: true

class Products::DetailResource < ProductResource
  typelize :string
  attribute :title, &:title

  typelize :string
  attribute :edit_path do |product|
    edit_product_path(product)
  end

  typelize({id: :number, title: :string})
  attribute :franchise do |product|
    {id: product.franchise_id, title: product.franchise.title}
  end

  typelize "Array<{ id: number; title: string }>"
  attribute :brands do |product|
    product.brands.map { |brand| {id: brand.id, title: brand.title} }
  end

  typelize "Array<{ id: number; value: string }>"
  attribute :sizes do |product|
    product.sizes.map { |size| {id: size.id, value: size.value} }
  end

  typelize "Array<{ id: number; value: string }>"
  attribute :versions do |product|
    product.versions.map { |version| {id: version.id, value: version.value} }
  end

  typelize "Array<{ id: number; value: string }>"
  attribute :colors do |product|
    product.colors.map { |color| {id: color.id, value: color.value} }
  end

  attributes :shape

  typelize :string, nullable: true
  attribute :description_html do |product|
    product.description.body&.to_html
  end

  typelize "Array<Media>"
  attribute :media do |product|
    MediaResource.attached(product.media)
  end

  typelize({store_id: "string | null", id_short: "string | null", tag_list: "Array<string>", product_url: :string}, nullable: true)
  attribute :shopify_info do |product|
    info = product.shopify_info
    {store_id: info.store_id, id_short: info.id_short, tag_list: info.tag_list, product_url: product.build_shopify_url} if info
  end

  typelize({store_id: "string | null", product_url: "string | null"}, nullable: true)
  attribute :woo_info do |product|
    info = product.woo_info
    {store_id: info.store_id, product_url: info.product_url} if info
  end

  typelize "Array<{ key: string; label: string; value: string }>"
  attribute :created_at_columns do |product|
    timestamp_columns(product, :created_at)
  end

  typelize "Array<{ key: string; label: string; value: string }>"
  attribute :updated_at_columns do |product|
    timestamp_columns(product, :updated_at)
  end

  typelize :boolean
  attribute :shopify_linked, &:shopify_linked?

  typelize :boolean
  attribute :can_pull_from_shopify do |_product|
    params[:can_pull_from_shopify] == true
  end

  typelize :string
  attribute :shopify_pull_path do |product|
    product_shopify_pull_path(product)
  end

  typelize :string
  attribute :new_purchase_path do |product|
    new_purchase_path(product:)
  end

  def timestamp_columns(product, attribute)
    columns = [{key: attribute.to_s.delete_suffix("_at"), label: "StoreMate", value: product.public_send(attribute)}]

    %i[shopify woo].each do |store_name|
      value = product.public_send("#{store_name}_info")&.public_send("ext_#{attribute}")
      columns << {key: store_name.to_s, label: store_name.to_s.titleize, value:} if value.present?
    end

    columns.map { |column| column.merge(value: format_date(column[:value])) }
  end
end
