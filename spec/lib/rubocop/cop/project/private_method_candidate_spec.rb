# frozen_string_literal: true

require "rubocop"
require "rubocop/database_validations/plugin"
require "rubocop/rspec/support"
require_relative "../../../../../lib/rubocop/cop/project/private_method_candidate"

RSpec.describe RuboCop::Cop::Project::PrivateMethodCandidate, :config do
  let(:cop_config) { {} }

  it "flags a public method reached only from a private method" do
    expect_offense(<<~RUBY)
      class Foo
        def helper; end
            ^^^^^^ `Foo#helper` is reached only through private same-owner calls. Make it private or explicitly preserve its public API.

        private

        def validate
          helper
        end
      end
    RUBY
  end

  it "accepts a public method reached from a public method" do
    expect_no_offenses(<<~RUBY)
      class Foo
        def entry
          helper
        end

        def helper; end

        private

        def validate
          helper
        end
      end
    RUBY
  end

  it "accepts an uncalled public method" do
    expect_no_offenses(<<~RUBY)
      class Foo
        def entry; end
      end
    RUBY
  end

  it "accepts a private helper" do
    expect_no_offenses(<<~RUBY)
      class Foo
        private

        def validate
          helper
        end

        def helper; end
      end
    RUBY
  end

  it "treats explicit self calls as same-owner calls" do
    expect_offense(<<~RUBY)
      class Foo
        def helper; end
            ^^^^^^ `Foo#helper` is reached only through private same-owner calls. Make it private or explicitly preserve its public API.

        private

        def validate
          self.helper
        end
      end
    RUBY
  end

  it "ignores calls through another receiver" do
    expect_no_offenses(<<~RUBY)
      class Foo
        def helper; end

        private

        def validate(other)
          other.helper
        end
      end
    RUBY
  end
end
