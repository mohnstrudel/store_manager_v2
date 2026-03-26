# frozen_string_literal: true

module BreadcrumbsHelper
  # Renders meta tag with breadcrumb data for the current page
  # Used by the Stimulus breadcrumbs controller to update the trail
  #
  # The meta tag serves as a bridge between server-side and client-side:
  # - Server determines the breadcrumb name (e.g., @product.title)
  # - Client (Stimulus) reads this meta tag to update the trail in sessionStorage
  #
  # Example output:
  #   <meta name="breadcrumb" content="Test Product" data-url="/products/123">
  #
  def breadcrumb_meta_tag
    breadcrumb_title = determine_breadcrumb_title
    return if breadcrumb_title.blank?

    tag.meta(
      name: "breadcrumb",
      content: breadcrumb_title,
      data: {url: request.path}
    )
  end

  def breadcrumbs
    render "shared/breadcrumbs"
  end

  private

  def determine_breadcrumb_title
    special_title = special_route_title
    return special_title if special_title

    case action_name
    when "show"
      record_name || controller_name_singular
    when "edit"
      "Edit #{record_name}"
    when "new"
      "New #{controller_name_singular}"
    else
      controller_name.titleize
    end
  end

  def special_route_title
    special_route_titles.fetch("#{controller_path}##{action_name}", nil)&.call
  end

  def special_route_titles
    @special_route_titles ||= {
      "dashboard/debts#show" => -> { "Debts" },
      "dashboard#index" => -> { "Dashboard" },
      "dashboard#noop" => -> { "Dashboard" },
      "warehouses/details#show" => -> { instance_variable_get(:@warehouse)&.name }
    }
  end

  def record_name
    return unless record

    if record.respond_to?(:title)
      record.title
    elsif record.respond_to?(:name)
      record.name
    elsif record.respond_to?(:value)
      record.value
    end
  end

  def record
    @record ||= instance_variable_get("@#{controller_name.singularize}")
  end

  def controller_name_singular
    controller_name.titleize.singularize
  end
end
