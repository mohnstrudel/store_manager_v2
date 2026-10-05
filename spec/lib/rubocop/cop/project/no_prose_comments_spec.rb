# frozen_string_literal: true

require "rubocop"
require "rubocop/database_validations/plugin"
require "rubocop/rspec/support"
require_relative "../../../../../lib/rubocop/cop/project/no_prose_comments"

RSpec.describe RuboCop::Cop::Project::NoProseComments, :config do
  let(:cop_config) { {} }

  it "flags a leading prose comment" do
    expect_offense(<<~RUBY)
      # This is a prose explanation.
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not add prose comments to code; use names, structure, and tests.
      def foo; end
    RUBY
  end

  it "flags an inline trailing prose comment" do
    expect_offense(<<~RUBY)
      value = compute # explain the computation
                      ^^^^^^^^^^^^^^^^^^^^^^^^^ Do not add prose comments to code; use names, structure, and tests.
    RUBY
  end

  it "flags TODO and FIXME comments" do
    expect_offense(<<~RUBY)
      # TODO: refactor this method
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not add prose comments to code; use names, structure, and tests.
      # FIXME: handle edge case
      ^^^^^^^^^^^^^^^^^^^^^^^^^ Do not add prose comments to code; use names, structure, and tests.
      def foo; end
    RUBY
  end

  it "accepts the frozen_string_literal magic comment" do
    expect_no_offenses(<<~RUBY)
      # frozen_string_literal: true

      def foo; end
    RUBY
  end

  it "accepts an exact rubocop disable/enable directive pair" do
    expect_no_offenses(<<~RUBY)
      def foo # rubocop:disable Metrics/MethodLength
        1
      end # rubocop:enable Metrics/MethodLength
    RUBY
  end

  it "accepts a rubocop disable directive carrying its documented reason suffix" do
    expect_no_offenses(<<~RUBY)
      x = 1 # rubocop:disable Rails/SkipsModelValidations -- bulk cache refresh; per-row validation too slow
    RUBY
  end

  it "accepts a structurally recognized schema information block" do
    expect_no_offenses(<<~RUBY)
      # == Schema Information
      #
      # Table name: foos
      #
      #  id :bigint
      #
      class Foo
      end
    RUBY
  end

  it "flags a malformed lookalike magic comment" do
    expect_offense(<<~RUBY)
      # frozen string literal: true
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not add prose comments to code; use names, structure, and tests.
      def foo; end
    RUBY
  end

  it "flags a malformed lookalike schema header" do
    expect_offense(<<~RUBY)
      # == schema information
      ^^^^^^^^^^^^^^^^^^^^^^^ Do not add prose comments to code; use names, structure, and tests.
      class Foo
      end
    RUBY
  end

  it "has no general suppression escape hatch for an invented marker" do
    expect_offense(<<~RUBY)
      # noprose: explanation of why this needs a comment
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not add prose comments to code; use names, structure, and tests.
      def foo; end
    RUBY
  end
end
