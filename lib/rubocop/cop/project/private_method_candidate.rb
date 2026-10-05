# frozen_string_literal: true

module RuboCop
  module Cop
    module Project
      class PrivateMethodCandidate < Base
        include VisibilityHelp

        MSG = "`%<owner>s#%<method>s` is reached only through private same-owner calls. " \
              "Make it private or explicitly preserve its public API."

        DESCENT_BOUNDARY_TYPES = %i[def defs class module sclass].freeze

        def on_class(node)
          check_owner(node)
        end

        def on_module(node)
          check_owner(node)
        end

        private

        def check_owner(owner_node)
          definitions = collect_instance_definitions(owner_node.body)
          link_callers(definitions)

          definitions.each do |definition|
            next unless definition.public?
            next if definition.callers.empty?
            next unless definition.callers.all?(&:private?)

            add_offense(definition.node.loc.name, message: format(MSG, owner: owner_node.identifier.source, method: definition.name))
          end
        end

        def collect_instance_definitions(body_node)
          return [] unless body_node

          statements = body_node.begin_type? ? body_node.children : [body_node]
          statements.filter_map do |statement|
            Definition.new(statement, statement.method_name.to_s, node_visibility(statement)) if statement.def_type?
          end
        end

        def link_callers(definitions)
          definitions_by_name = {}
          definitions.each do |definition|
            definitions_by_name[definition.name] = definition
          end

          definitions.each do |definition|
            collect_calls(definition.node.body).uniq.each do |name|
              definitions_by_name[name]&.callers&.<< definition
            end
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
          send_node.method_name.to_s if receiver.nil? || receiver.self_type?
        end

        Definition = Struct.new(:node, :name, :visibility, :callers) do
          def initialize(node, name, visibility)
            super(node, name, visibility, [])
          end

          def public?
            visibility == :public
          end

          def private?
            visibility == :private
          end
        end
        private_constant :Definition
      end
    end
  end
end
