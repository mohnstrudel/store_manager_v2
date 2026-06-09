# frozen_string_literal: true

module FranchiseHelper
  def franchise_form_props(franchise)
    {
      franchise: franchise_props(franchise)
    }
  end

  def franchise_props(franchise)
    {
      id: franchise.id,
      title: franchise.title.to_s,
      created_at: formatted_timestamp(franchise.created_at),
      updated_at: formatted_timestamp(franchise.updated_at)
    }
  end
end
