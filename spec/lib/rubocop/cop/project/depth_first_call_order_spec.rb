# frozen_string_literal: true

require "rubocop"
require "rubocop/database_validations/plugin"
require "rubocop/rspec/support"
require_relative "../../../../../lib/rubocop/cop/project/depth_first_call_order"

RSpec.describe RuboCop::Cop::Project::DepthFirstCallOrder, :config do
  let(:cop_config) { {} }

  context "with one-level and multi-level traversal" do
    it "accepts a caller followed by its callee subtree, deepest first" do
      expect_no_offenses(<<~RUBY)
        class Foo
          def a
            b
            c
          end

          def b
            d
          end

          def d; end

          def c; end
        end
      RUBY
    end

    it "flags a callee subtree interrupted by a later sibling callee" do
      expect_offense(<<~RUBY)
        class Foo
          def a
            b
            c
          end

          def b
            d
          end

          def c; end
          def d; end
              ^ `Foo#d` must be defined before `Foo#c` (depth-first call order).
        end
      RUBY
    end
  end

  context "with zero-incoming roots and disconnected declarations" do
    it "accepts independent roots kept in their declared source order" do
      expect_no_offenses(<<~RUBY)
        class Foo
          def one; end

          def two; end

          def three; end
        end
      RUBY
    end
  end

  context "with a callee-before-caller violation" do
    it "flags a public callee declared above its public caller" do
      expect_offense(<<~RUBY)
        class Foo
          def helper; end

          def entry_point
              ^^^^^^^^^^^ `Foo#entry_point` must be defined before `Foo#helper` (depth-first call order).
            helper
          end
        end
      RUBY
    end
  end

  context "with shared helpers" do
    it "accepts a helper positioned right after the first root that reaches it" do
      expect_no_offenses(<<~RUBY)
        class Foo
          def root_one
            helper
          end

          def helper; end

          def root_two
            helper
          end
        end
      RUBY
    end

    it "flags a helper kept before the root that first reaches it" do
      expect_offense(<<~RUBY)
        class Foo
          def root_one
            helper
          end

          def root_two
            helper
          end

          def helper; end
              ^^^^^^ `Foo#helper` must be defined before `Foo#root_two` (depth-first call order).
        end
      RUBY
    end
  end

  context "with recursive cycles" do
    it "terminates a mutual cycle and accepts its declared order" do
      expect_no_offenses(<<~RUBY)
        class Foo
          def a
            b
          end

          def b
            a
          end
        end
      RUBY
    end

    it "terminates a cycle reached from an external root" do
      expect_no_offenses(<<~RUBY)
        class Foo
          def entry
            a
          end

          def a
            b
          end

          def b
            a
          end
        end
      RUBY
    end
  end

  context "with visibility projection" do
    it "accepts a private helper positioned after the visibility boundary" do
      expect_no_offenses(<<~RUBY)
        class Foo
          def public_caller
            helper
          end

          private

          def helper; end
        end
      RUBY
    end

    it "still orders private helpers relative to each other by caller order" do
      expect_offense(<<~RUBY)
        class Foo
          def a
            helper_a
          end

          def b
            helper_b
          end

          private

          def helper_b; end
          def helper_a; end
              ^^^^^^^^ `Foo#helper_a` must be defined before `Foo#helper_b` (depth-first call order).
        end
      RUBY
    end
  end

  context "with class versus instance methods" do
    it "checks singleton and instance graphs independently" do
      expect_offense(<<~RUBY)
        class Foo
          def self.entry
            self.helper
          end

          def self.helper; end

          def instance_helper; end

          def instance_entry
              ^^^^^^^^^^^^^^ `Foo#instance_entry` must be defined before `Foo#instance_helper` (depth-first call order).
            instance_helper
          end
        end
      RUBY
    end
  end

  context "with `class << self`" do
    it "accepts singleton methods declared inside class << self in call order" do
      expect_no_offenses(<<~RUBY)
        class Foo
          class << self
            def entry
              helper
            end

            def helper; end
          end
        end
      RUBY
    end

    it "flags singleton methods declared inside class << self out of call order" do
      expect_offense(<<~RUBY)
        class Foo
          class << self
            def helper; end

            def entry
                ^^^^^ `Foo.entry` must be defined before `Foo.helper` (depth-first call order).
              helper
            end
          end
        end
      RUBY
    end
  end

  context "with ignored Ruby dispatch" do
    it "ignores calls through another receiver" do
      expect_no_offenses(<<~RUBY)
        class Foo
          def helper; end

          def entry
            SomeService.helper
          end
        end
      RUBY
    end

    it "ignores super" do
      expect_no_offenses(<<~RUBY)
        class Foo
          def helper; end

          def entry
            super
          end
        end
      RUBY
    end

    it "ignores symbol callbacks passed to macros" do
      expect_no_offenses(<<~RUBY)
        class Foo
          before_action :helper

          def helper; end

          def entry; end
        end
      RUBY
    end

    it "ignores alias_method targets" do
      expect_no_offenses(<<~RUBY)
        class Foo
          def helper; end
          alias_method :aliased_helper, :helper

          def entry; end
        end
      RUBY
    end

    it "ignores dynamic dispatch through send" do
      expect_no_offenses(<<~RUBY)
        class Foo
          def helper; end

          def entry
            send(:helper)
          end
        end
      RUBY
    end

    it "ignores calls to generated accessor methods and inherited methods" do
      expect_no_offenses(<<~RUBY)
        class Foo < ApplicationRecord
          attr_accessor :name

          def entry
            self.name = "value"
            save!
            helper
          end

          def helper; end
        end
      RUBY
    end
  end
end
