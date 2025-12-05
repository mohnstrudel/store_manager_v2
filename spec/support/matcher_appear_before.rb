RSpec::Matchers.define :appear_before do |later_content|
  match do |earlier_content|
    earlier_index = page.body.index(earlier_content)
    later_index = page.body.index(later_content)

    # Both contents should be found
    return false if earlier_index.nil? || later_index.nil?

    earlier_index < later_index
  end

  failure_message do |earlier_content|
    earlier_index = page.body.index(earlier_content)
    later_index = page.body.index(later_content)

    if earlier_index.nil?
      "Expected \"#{earlier_content}\" to appear on the page, but it was not found"
    elsif later_index.nil?
      "Expected \"#{later_content}\" to appear on the page, but it was not found"
    else
      "Expected \"#{earlier_content}\" to appear before \"#{later_content}\", but it appears after"
    end
  end
end
