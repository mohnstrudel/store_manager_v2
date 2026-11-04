# frozen_string_literal: true

require "rubocop"
require "rubocop/database_validations/plugin"
require "rubocop/rspec/support"
require_relative "../../../../../lib/rubocop/cop/project/capability_module_name"

RSpec.describe RuboCop::Cop::Project::CapabilityModuleName, :config do
  let(:cop_config) { {} }

  context "with concerns" do
    it "flags a compact-named concern ending in `ing`" do
      expect_offense(<<~RUBY)
        module Sale::Reviewing
               ^^^^^^^^^^^^^^^ `Sale::Reviewing` is named for a screen, job, or mechanism; name the capability for what the record can be (`Revisable`, `Linkable`, `Titled`).
          extend ActiveSupport::Concern
        end
      RUBY
    end

    it "flags a nested concern ending in `ing`" do
      expect_offense(<<~RUBY)
        class Product
          module Shopify
            module Pushing
                   ^^^^^^^ `Pushing` is named for a screen, job, or mechanism; name the capability for what the record can be (`Revisable`, `Linkable`, `Titled`).
              extend ActiveSupport::Concern

              def push; end
            end
          end
        end
      RUBY
    end

    it "flags a concern that extends a root-qualified `::ActiveSupport::Concern`" do
      expect_offense(<<~RUBY)
        module FormHandling
               ^^^^^^^^^^^^ `FormHandling` is named for a screen, job, or mechanism; name the capability for what the record can be (`Revisable`, `Linkable`, `Titled`).
          extend ::ActiveSupport::Concern
        end
      RUBY
    end

    it "accepts a concern named for what the record can be" do
      expect_no_offenses(<<~RUBY)
        module Sale::Revisable
          extend ActiveSupport::Concern
        end
      RUBY
    end

    it "accepts a business noun concern" do
      expect_no_offenses(<<~RUBY)
        module Sale::Settlement
          extend ActiveSupport::Concern
        end
      RUBY
    end
  end

  context "with non-concerns" do
    it "accepts a plain module ending in `ing`" do
      expect_no_offenses(<<~RUBY)
        module Sale::Shipping
          def self.call; end
        end
      RUBY
    end

    it "accepts a class ending in `ing`" do
      expect_no_offenses(<<~RUBY)
        class Sale::Pricing
          extend ActiveSupport::Concern
        end
      RUBY
    end
  end

  context "with AllowedNames" do
    let(:cop_config) { {"AllowedNames" => ["Shipping"]} }

    it "accepts an allowed business noun ending in `ing`" do
      expect_no_offenses(<<~RUBY)
        module PurchaseItem::Shipping
          extend ActiveSupport::Concern
        end
      RUBY
    end

    it "still flags names that are not allowed" do
      expect_offense(<<~RUBY)
        module Sale::Listing
               ^^^^^^^^^^^^^ `Sale::Listing` is named for a screen, job, or mechanism; name the capability for what the record can be (`Revisable`, `Linkable`, `Titled`).
          extend ActiveSupport::Concern
        end
      RUBY
    end
  end
end
