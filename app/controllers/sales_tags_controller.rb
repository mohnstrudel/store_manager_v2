# frozen_string_literal: true

class SalesTagsController < ApplicationController
  before_action :set_sales_tag, only: %i[show edit update]

  def index
    render_catalog
  end

  def show
    render_catalog(detail: @sales_tag)
  end

  def new
    render_catalog(form: SalesTag.new(name: ""))
  end

  def edit
    render_catalog(form: @sales_tag)
  end

  def create
    SalesTag.find_or_create_normalized!(**sales_tag_params)

    redirect_to sales_tags_path, notice: "Sales tag saved", status: :see_other
  rescue ActiveRecord::RecordInvalid => error
    redirect_to new_sales_tag_path, inertia: inertia_errors(error.record.errors), status: :see_other
  end

  def update
    @sales_tag.revise!(sales_tag_params)

    redirect_to sales_tags_path, notice: "Sales tag saved", status: :see_other
  rescue ActiveRecord::RecordInvalid => error
    redirect_to edit_sales_tag_path(@sales_tag), inertia: inertia_errors(error.record.errors), status: :see_other
  end

  def destroy
    SalesTag.find_by(id: params.expect(:id))&.destroy!

    redirect_to sales_tags_path, notice: "Sales tag deleted", status: :see_other
  end

  private

  def render_catalog(form: nil, detail: nil)
    render inertia: "SalesTags/Index", props: {
      sales_tags: SalesTag.with_usage_count.alphabetical.map { |tag| helpers.sales_tag_catalog_props(tag) },
      sales_tag: form && helpers.sales_tag_props(form),
      sales_tag_detail: detail && helpers.sales_tag_detail_props(detail),
      tag_colors: SalesTag::COLORS,
      can_manage_sales_tags: policy(:sales_tag).update?
    }
  end

  def sales_tag_params
    params.expect(sales_tag: [:name, :color]).to_h.symbolize_keys.reverse_merge(name: nil)
  end

  def set_sales_tag
    @sales_tag = SalesTag.find(params.expect(:id))
  end
end
