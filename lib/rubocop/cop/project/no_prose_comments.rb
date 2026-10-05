# frozen_string_literal: true

module RuboCop
  module Cop
    module Project
      class NoProseComments < Base
        MSG = "Do not add prose comments to code; use names, structure, and tests."

        SHEBANG_RE = /\A#!/
        MAGIC_COMMENT_RE =
          /\A#\s*(?:-\*-\s*)?(?:frozen_string_literal|encoding|coding|warn_indent|shareable_constant_value)\s*:\s*\S.*?(?:\s*-\*-)?\s*\z/
        RUBOCOP_DIRECTIVE_RE = /\A#\s*rubocop:(?:disable|enable|todo)\s+\S.*\z/
        SCHEMA_HEADER_RE = /\A#\s*==\s*Schema Information\s*\z/

        def on_new_investigation
          schema_comments = schema_block_comments(processed_source.comments)

          processed_source.comments.each do |comment|
            next if allowed?(comment, schema_comments)

            add_offense(comment, message: MSG)
          end
        end

        private

        def schema_block_comments(comments)
          schema_comments = Set.new

          comments.each_with_index do |comment, index|
            next unless SCHEMA_HEADER_RE.match?(comment.text)

            schema_comments.merge(contiguous_run(comments, index))
          end

          schema_comments
        end

        def contiguous_run(comments, start_index)
          run = [comments[start_index]]
          line = comments[start_index].loc.line

          ((start_index + 1)...comments.size).each do |index|
            candidate = comments[index]
            break unless candidate.loc.line == line + 1

            run << candidate
            line = candidate.loc.line
          end

          run
        end

        def allowed?(comment, schema_comments)
          text = comment.text

          SHEBANG_RE.match?(text) ||
            MAGIC_COMMENT_RE.match?(text) ||
            RUBOCOP_DIRECTIVE_RE.match?(text) ||
            schema_comments.include?(comment)
        end
      end
    end
  end
end
