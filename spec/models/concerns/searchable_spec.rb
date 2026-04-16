# frozen_string_literal: true

require "rails_helper"

RSpec.describe Searchable do
  let(:searchable_class) do
    Class.new do
      extend Searchable::ClassMethods

      class << self
        attr_reader :scope_name, :scope_options

        def pg_search_scope(scope_name, **options)
          @scope_name = scope_name
          @scope_options = options
        end
      end
    end
  end

  describe ".set_search_scope" do
    it "enables prefix matching for tsearch by default" do
      searchable_class.set_search_scope(:search, against: [:title])

      expect(searchable_class.scope_name).to eq(:search)
      expect(searchable_class.scope_options).to include(
        against: [:title],
        using: {tsearch: {prefix: true}}
      )
    end

    it "preserves other tsearch options while forcing prefix matching" do
      searchable_class.set_search_scope(
        :search,
        against: [:title],
        using: {
          tsearch: {dictionary: "simple"},
          trigram: {threshold: 0.2}
        }
      )

      expect(searchable_class.scope_options[:using]).to eq(
        tsearch: {dictionary: "simple", prefix: true},
        trigram: {threshold: 0.2}
      )
    end
  end
end
