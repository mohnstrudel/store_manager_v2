# frozen_string_literal: true

module Helpers
  module ReactSelect
    # Select an option from a react-select (SmartSelect) identified by its label text.
    # Works inside `within` blocks since menu renders in the same container (no portal).
    # Re-queries the container after each interaction to avoid stale Ferrum node references.
    def choose_react_select(option_text, from:)
      rs_container_for(from).find(".rs__control").click
      # Re-query after the React re-render that opens the menu
      rs_container_for(from).find(".rs__option", text: option_text).click
    end

    # Add a tag to a react-select creatable multi field identified by its label text.
    # Types the tag text and presses Enter to create it.
    def add_react_select_tag(tag_text, to:)
      rs_container_for(to).find(".rs__control").click
      # Re-query after the React re-render that opens the control
      input = rs_container_for(to).find(".rs__input", visible: :all)
      input.set(tag_text)
      input.send_keys :return
    end

    # Clear all selected values from a react-select (single or multi).
    def clear_react_select(from:)
      container = rs_container_for(from)
      if container.has_css?(".rs__clear-indicator", wait: 2)
        container.find(".rs__clear-indicator").click
      else
        # Remove chips one by one, re-querying after each removal to avoid stale elements
        while rs_container_for(from).has_css?(".rs__multi-value__remove", wait: 1)
          rs_container_for(from).first(".rs__multi-value__remove").click
        end
      end
    end

    private

    # Returns the react-select container div that follows the given label text.
    # Always performs a fresh DOM traversal to avoid stale node references.
    def rs_container_for(label_text)
      find("label", text: label_text, exact_text: false).find(:xpath, "following-sibling::div[1]")
    end
  end
end
