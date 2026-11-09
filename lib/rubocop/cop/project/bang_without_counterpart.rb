# frozen_string_literal: true

module RuboCop
  module Cop
    module Project
      class BangWithoutCounterpart < Base
        MSG = "`%<owner>s%<separator>s%<method>s` has no non-bang counterpart " \
              "`%<owner>s%<separator>s%<counterpart>s`; drop the `!`."

        def_node_matcher :class_methods_block?, <<~PATTERN
          (block (send nil? :class_methods) _ _)
        PATTERN

        def on_class(node)
          check_owner(node)
        end

        def on_module(node)
          check_owner(node)
        end

        private

        def check_owner(owner_node)
          instance_defs, singleton_defs = collect_definitions(owner_node.body)

          report_missing_counterparts(owner_node, instance_defs, separator: "#")
          report_missing_counterparts(owner_node, singleton_defs, separator: ".")
        end

        def collect_definitions(body_node)
          instance_defs = []
          singleton_defs = []

          each_top_level_statement(body_node) do |statement|
            collect_statement_definition(statement, instance_defs, singleton_defs)
          end

          [instance_defs, singleton_defs]
        end

        def each_top_level_statement(node)
          return unless node

          if node.begin_type?
            node.children.each { |child| yield child }
          else
            yield node
          end
        end

        def collect_statement_definition(statement, instance_defs, singleton_defs)
          case statement.type
          when :def
            instance_defs << statement
          when :defs
            singleton_defs << statement if statement.receiver.self_type?
          when :sclass
            collect_nested_definitions(statement.body, singleton_defs) if statement.identifier.self_type?
          when :block
            collect_nested_definitions(statement.body, singleton_defs) if class_methods_block?(statement)
          end
        end

        def collect_nested_definitions(body_node, singleton_defs)
          each_top_level_statement(body_node) do |inner|
            singleton_defs << inner if inner.def_type?
          end
        end

        def report_missing_counterparts(owner_node, definitions, separator:)
          names = definitions.to_set { |definition| definition.method_name.to_s }

          definitions.each do |definition|
            name = definition.method_name.to_s
            next unless name.end_with?("!")

            counterpart = name.delete_suffix("!")
            next if names.include?(counterpart)

            message = format(MSG, owner: owner_node.identifier.source, separator:, method: name, counterpart:)
            add_offense(definition.loc.name, message:)
          end
        end
      end
    end
  end
end
