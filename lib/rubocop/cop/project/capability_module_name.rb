# frozen_string_literal: true

module RuboCop
  module Cop
    module Project
      class CapabilityModuleName < Base
        MSG = "`%<module>s` is named for a screen, job, or mechanism; " \
              "name the capability for what the record can be (`Revisable`, `Linkable`, `Titled`)."

        SCREEN_OR_JOB_SUFFIX = "ing"

        def_node_matcher :extends_concern?, <<~PATTERN
          (send nil? :extend (const (const {nil? cbase} :ActiveSupport) :Concern))
        PATTERN

        def on_module(node)
          return unless concern?(node)

          name = node.identifier.short_name.to_s
          return unless screen_or_job_shaped?(name)

          add_offense(node.identifier, message: format(MSG, module: node.identifier.source))
        end

        private

        def concern?(module_node)
          body = module_node.body
          return false unless body

          statements = body.begin_type? ? body.children : [body]
          statements.any? { |statement| extends_concern?(statement) }
        end

        def screen_or_job_shaped?(name)
          return false if allowed_names.include?(name)

          name.end_with?(SCREEN_OR_JOB_SUFFIX)
        end

        def allowed_names
          Array(cop_config["AllowedNames"])
        end
      end
    end
  end
end
