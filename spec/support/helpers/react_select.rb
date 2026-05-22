# frozen_string_literal: true

module Helpers
  module ReactSelect
    # Select an option from a react-select (SmartSelect) identified by its label text.
    # Works inside `within` blocks since menu renders in the same container (no portal).
    # Re-queries the container after each interaction to avoid stale Ferrum node references.
    def choose_react_select(option_text, from:)
      container_xpath = react_select_container_xpath(from)
      find(:xpath, "#{container_xpath}//div[contains(@class, 'rs__control')]", match: :first, visible: :all).click
      # Re-query after the React re-render that opens the menu
      find(:xpath, "#{container_xpath}//div[contains(@class, 'rs__option') and normalize-space(.)=#{option_text.inspect}]", match: :first, visible: :all).click
    end

    # Add a tag to a react-select creatable multi field identified by its label text.
    # Types the tag text and presses Enter to create it.
    def add_react_select_tag(tag_text, to:)
      container_xpath = react_select_container_xpath(to)
      find(:xpath, "#{container_xpath}//div[contains(@class, 'rs__control')]", match: :first, visible: :all).click
      # Re-query after the React re-render that opens the control
      input = find(:xpath, "#{container_xpath}//input[contains(@class, 'rs__input')]", match: :first, visible: :all)
      input.set(tag_text)
      input.send_keys :return
    end

    # Clear all selected values from a react-select (single or multi).
    def clear_react_select(from:)
      container_xpath = react_select_container_xpath(from)
      container = find(:xpath, container_xpath, match: :first, visible: :all)
      if container.has_css?(".rs__clear-indicator", wait: 2)
        find(:xpath, "#{container_xpath}//div[contains(@class, 'rs__clear-indicator')]", match: :first, visible: :all).click
      else
        # Remove chips one by one, re-querying after each removal to avoid stale elements
        while find(:xpath, container_xpath, match: :first, visible: :all).has_css?(".rs__multi-value__remove", wait: 1)
          find(:xpath, "#{container_xpath}//div[contains(@class, 'rs__multi-value__remove')]", match: :first, visible: :all).click
        end
      end
    end

    private

    # Returns the react-select container div that follows the given label text.
    # Always performs a fresh DOM traversal to avoid stale node references.
    def rs_container_for(label_text)
      find(:xpath, react_select_container_xpath(label_text))
    end

    def react_select_container_xpath(label_text)
      %(//label[contains(normalize-space(.), #{label_text.inspect})]/following-sibling::div[1])
    end
  end
end
