# frozen_string_literal: true
module Helpers
  module SlimSelect
    def slim_select(label, option)
      find(".ss-values", text: label).click
      find(".ss-option", text: option).click
    end
  end
end
