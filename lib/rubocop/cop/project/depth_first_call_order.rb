# frozen_string_literal: true

module RuboCop
  module Cop
    module Project
      class DepthFirstCallOrder < Base
        include VisibilityHelp

        MSG = "`%<owner>s%<separator>s%<callee>s` must be defined before " \
              "`%<owner>s%<separator>s%<caller>s` (depth-first call order)."

        DESCENT_BOUNDARY_TYPES = %i[def defs class module sclass].freeze

        def on_class(node)
          check_owner(node)
        end

        def on_module(node)
          check_owner(node)
        end

        private

        def check_owner(owner_node)
          instance_defs, singleton_defs = collect_definitions(owner_node.body)

          check_graph(owner_node, instance_defs, kind: :instance)
          check_graph(owner_node, singleton_defs, kind: :singleton)
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
            instance_defs << Definition.new(statement, statement.method_name.to_s)
          when :defs
            singleton_defs << Definition.new(statement, statement.method_name.to_s) if statement.receiver.self_type?
          when :sclass
            collect_sclass_definitions(statement, singleton_defs)
          end
        end

        def collect_sclass_definitions(sclass_node, singleton_defs)
          return unless sclass_node.identifier.self_type?

          each_top_level_statement(sclass_node.body) do |inner|
            singleton_defs << Definition.new(inner, inner.method_name.to_s) if inner.def_type?
          end
        end

        def check_graph(owner_node, definitions, kind:)
          return if definitions.size < 2

          link_callees(definitions)
          expected_order = depth_first_order(definitions)
          report_bucket_inversions(owner_node, definitions, expected_order, kind)
        end

        def link_callees(definitions)
          by_name = {}
          definitions.each { |definition| by_name[definition.name] = definition }

          definitions.each do |definition|
            definition.callees = collect_calls(definition.node.body).filter_map { |name| by_name[name.to_s] }.uniq
          end
        end

        def collect_calls(body_node)
          return [] unless body_node

          each_direct_call(body_node).filter_map { |call_node| same_owner_call_name(call_node) }
        end

        def each_direct_call(node, &block)
          return enum_for(:each_direct_call, node) unless block

          yield node if node.send_type? || node.csend_type?

          node.each_child_node do |child|
            next if DESCENT_BOUNDARY_TYPES.include?(child.type)

            each_direct_call(child, &block)
          end
        end

        def same_owner_call_name(send_node)
          receiver = send_node.receiver
          send_node.method_name if receiver.nil? || receiver.self_type?
        end

        def depth_first_order(definitions)
          visited = Set.new
          ordered = []
          visit = lambda do |definition|
            next if visited.include?(definition)

            visited << definition
            ordered << definition
            definition.callees.each { |callee| visit.call(callee) }
          end

          roots = definitions.reject { |definition| incoming_edge?(definitions, definition) }
          roots.each { |definition| visit.call(definition) }
          definitions.each { |definition| visit.call(definition) }

          ordered
        end

        def incoming_edge?(definitions, target)
          definitions.any? { |definition| definition.callees.include?(target) }
        end

        def report_bucket_inversions(owner_node, definitions, expected_order, kind)
          expected_rank = expected_order.each_with_index.to_h

          definitions.group_by { |definition| structural_bucket(definition, kind) }.each_value do |bucket|
            bucket.each_cons(2) do |earlier, later|
              next if expected_rank[earlier] < expected_rank[later]

              report_inversion(owner_node, earlier, later, separator_for(kind))
            end
          end
        end

        def structural_bucket(definition, kind)
          return :class_methods if kind == :singleton
          return :initializer if definition.name == "initialize"

          node_visibility(definition.node)
        end

        def report_inversion(owner_node, earlier, later, separator)
          message = format(
            MSG,
            owner: owner_node.identifier.source,
            separator:,
            callee: later.name,
            caller: earlier.name
          )
          add_offense(later.node.loc.name, message:)
        end

        def separator_for(kind)
          (kind == :singleton) ? "." : "#"
        end

        Definition = Struct.new(:node, :name, :callees) do
          def initialize(node, name)
            super(node, name, [])
          end
        end
        private_constant :Definition
      end
    end
  end
end
