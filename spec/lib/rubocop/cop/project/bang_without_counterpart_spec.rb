# frozen_string_literal: true

require "rubocop"
require "rubocop/database_validations/plugin"
require "rubocop/rspec/support"
require_relative "../../../../../lib/rubocop/cop/project/bang_without_counterpart"

RSpec.describe RuboCop::Cop::Project::BangWithoutCounterpart, :config do
  let(:cop_config) { {} }

  context "with instance methods" do
    it "flags a bang method without a non-bang twin" do
      expect_offense(<<~RUBY)
        class Foo
          def close!; end
              ^^^^^^ `Foo#close!` has no non-bang counterpart `Foo#close`; drop the `!`.
        end
      RUBY
    end

    it "accepts a bang method with a non-bang twin" do
      expect_no_offenses(<<~RUBY)
        class Foo
          def close; end

          def close!; end
        end
      RUBY
    end

    it "flags a private bang method without a non-bang twin" do
      expect_offense(<<~RUBY)
        module Foo
          private

          def sync!; end
              ^^^^^ `Foo#sync!` has no non-bang counterpart `Foo#sync`; drop the `!`.
        end
      RUBY
    end

    it "accepts methods without a bang" do
      expect_no_offenses(<<~RUBY)
        class Foo
          def close; end

          def closed?; end
        end
      RUBY
    end
  end

  context "with singleton methods" do
    it "flags a `def self.x!` without a `def self.x`" do
      expect_offense(<<~RUBY)
        class Foo
          def self.import!; end
                   ^^^^^^^ `Foo.import!` has no non-bang counterpart `Foo.import`; drop the `!`.
        end
      RUBY
    end

    it "accepts a `def self.x!` with a `def self.x`" do
      expect_no_offenses(<<~RUBY)
        class Foo
          def self.import; end

          def self.import!; end
        end
      RUBY
    end

    it "flags a bang method inside `class << self` without a twin" do
      expect_offense(<<~RUBY)
        class Foo
          class << self
            def import!; end
                ^^^^^^^ `Foo.import!` has no non-bang counterpart `Foo.import`; drop the `!`.
          end
        end
      RUBY
    end

    it "accepts a `class << self` bang method whose twin is a `def self.x`" do
      expect_no_offenses(<<~RUBY)
        class Foo
          def self.import; end

          class << self
            def import!; end
          end
        end
      RUBY
    end

    it "flags a bang method inside a concern's `class_methods` block without a twin" do
      expect_offense(<<~RUBY)
        module Foo
          class_methods do
            def import!; end
                ^^^^^^^ `Foo.import!` has no non-bang counterpart `Foo.import`; drop the `!`.
          end
        end
      RUBY
    end
  end

  context "with mixed kinds" do
    it "does not count an instance method as the twin of a singleton bang method" do
      expect_offense(<<~RUBY)
        class Foo
          def import; end

          def self.import!; end
                   ^^^^^^^ `Foo.import!` has no non-bang counterpart `Foo.import`; drop the `!`.
        end
      RUBY
    end

    it "does not count a singleton method as the twin of an instance bang method" do
      expect_offense(<<~RUBY)
        class Foo
          def self.import; end

          def import!; end
              ^^^^^^^ `Foo#import!` has no non-bang counterpart `Foo#import`; drop the `!`.
        end
      RUBY
    end
  end

  context "with nested owners" do
    it "does not count a twin defined in a nested class" do
      expect_offense(<<~RUBY)
        class Foo
          def import!; end
              ^^^^^^^ `Foo#import!` has no non-bang counterpart `Foo#import`; drop the `!`.

          class Bar
            def import; end
          end
        end
      RUBY
    end
  end
end
