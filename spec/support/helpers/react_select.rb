# frozen_string_literal: true

module Helpers
  module ReactSelect
    def choose_react_select(option_text, from:)
      container_xpath = react_select_container_xpath(from)
      find(:xpath, "#{container_xpath}//div[contains(@class, 'rs__control')]", match: :first, visible: :all).click
      send_keys(option_text)
      send_keys(:enter)
    end

    def add_react_select_tag(tag_text, to:)
      container_xpath = react_select_container_xpath(to)
      find(:xpath, "#{container_xpath}//div[contains(@class, 'rs__control')]", match: :first, visible: :all).click
      input = find(:xpath, "#{container_xpath}//input[contains(@class, 'rs__input')]", match: :first, visible: :all)
      input.set(tag_text)
      input.send_keys :return
    end

    def clear_react_select(from:)
      container_xpath = react_select_container_xpath(from)
      container = find(:xpath, container_xpath, match: :first, visible: :all)
      if container.has_css?(".rs__clear-indicator", wait: 2)
        find(:xpath, "#{container_xpath}//div[contains(@class, 'rs__clear-indicator')]", match: :first, visible: :all).click
      else
        while find(:xpath, container_xpath, match: :first, visible: :all).has_css?(".rs__multi-value__remove", wait: 1)
          find(:xpath, "#{container_xpath}//div[contains(@class, 'rs__multi-value__remove')]", match: :first, visible: :all).click
        end
      end
    end

    private

    def react_select_container_xpath(label_text)
      %(.//label[contains(normalize-space(.), #{label_text.inspect})]/following-sibling::div[1])
    end

    def rs_container_for(label_text)
      find(:xpath, react_select_container_xpath(label_text))
    end
  end
end
