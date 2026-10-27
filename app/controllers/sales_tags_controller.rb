# frozen_string_literal: true

class SalesTagsController < ApplicationController
  def index
    render inertia: "SalesTags/Index", props: {
      sales_tags: SalesTag.matching(query).alphabetical.map { |tag| helpers.sales_tag_catalog_props(tag) },
      search: {q: query},
      tag_colors: SalesTag::COLORS
    }
  end

  def create
    SalesTag.find_or_create_normalized!(**sales_tag_params)

    redirect_to sales_tags_path(q: query.presence), status: :see_other
  rescue ActiveRecord::RecordInvalid => error
    redirect_to sales_tags_path(q: query.presence), inertia: inertia_errors(error.record.errors), status: :see_other
  end

  private

  def query
    params[:q].to_s.strip
  end

  def sales_tag_params
    params.expect(sales_tag: [:name, :color]).to_h.symbolize_keys.reverse_merge(name: nil)
  end
end
