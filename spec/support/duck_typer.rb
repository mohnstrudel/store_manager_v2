# frozen_string_literal: true

# Contract-testing helpers for interchangeable implementations. These prove
# structural interface compatibility only — pair with real behavioral
# examples for each implementation; matching method names does not prove
# matching semantics. See rails-testing's SKILL.md "Shared Contracts".
module DuckTyper
  # Declares an example asserting `described_class` implements every method
  # `canonical` exposes. Pass a small inline `Class.new` as `canonical` to
  # keep the contract's shape explicit in the spec, or a real class when its
  # own interface is what other implementations must match. Pass `methods:`
  # to check an explicit subset instead of the canonical class's full
  # public and private interface.
  def implement_canonical_interface(canonical, methods: nil)
    required = methods || canonical.public_instance_methods(false) + canonical.private_instance_methods(false)

    it "implements #{canonical}'s interface (#{required.sort.join(", ")})" do
      instance = described_class.allocate
      missing = required.reject { |method_name| instance.respond_to?(method_name, true) }

      expect(missing).to be_empty,
        "#{described_class} is missing #{canonical}'s required methods: #{missing.join(", ")}"
    end
  end
end

RSpec::Matchers.define :have_matching_interfaces do |other, methods:|
  match do |actual|
    @missing_on_actual = methods.reject { |method_name| actual.method_defined?(method_name) || actual.private_method_defined?(method_name) }
    @missing_on_other = methods.reject { |method_name| other.method_defined?(method_name) || other.private_method_defined?(method_name) }

    @missing_on_actual.empty? && @missing_on_other.empty?
  end

  failure_message do |actual|
    "expected #{actual} and #{other} to both implement #{methods.join(", ")}, " \
      "but #{actual} is missing #{@missing_on_actual.join(", ")} " \
      "and #{other} is missing #{@missing_on_other.join(", ")}"
  end
end

RSpec.configure do |config|
  config.extend DuckTyper
end
