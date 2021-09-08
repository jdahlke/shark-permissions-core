# frozen_string_literal: true

module Shark
  module Permissions
    class Changes
      attr_reader :effect
      attr_reader :privileges

      def initialize
        @privileges = {}
        @effect = {}
      end

      def add(field, old_value, new_value)
        return if old_value == new_value

        instance_variable_set("@#{field}", { old: old_value, new: old_value })
      end

      def add_privilege(key, old_value, new_value)
        @privileges[:old] ||= {}
        @privileges[:new] ||= {}
        @privileges[:old][key] = old_value
        @privileges[:new][key] = new_value
      end

      # @return [Boolean]
      # @api public
      def empty?
        effect.empty? && privileges.empty?
      end

      # @return [Boolean]
      # @api public
      def present?
        !empty?
      end
    end
  end
end
