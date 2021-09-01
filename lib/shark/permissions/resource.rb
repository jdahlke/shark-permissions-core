# frozen_string_literal: true

module Shark
  module Permissions
    class Resource
      attr_reader :name, :parts

      def initialize(value)
        @name = case value
                when String
                  value
                when Array
                  value.map(&:to_s).join(Shark::Permissions.delimiter)
                end
        @parts = @name.split(Shark::Permissions.delimiter)
      end

      def ancestors_and_self
        names = []
        parts.each_with_index do |_, i|
          names << parts[0..i].join(Shark::Permissions.delimiter)
        end

        names
      end

      def ancestors
        ancestors_and_self[0..-2]
      end

      def parent
        parent_name = parts[0..-2].join(Shark::Permissions.delimiter)
        parent_name.presence
      end

      def subresource_of?(value)
        return true if name == value

        regexp = value.gsub('*', '[a-z\-_0-9]*')
        "#{name}::".match(/\A#{regexp}::/).present?
      end

      def super_resource_of?(value)
        return true if name == value

        regexp = name.gsub('*', '[a-z\-_0-9]*')
        "#{value}::".match(/\A#{regexp}::/).present?
      end

      def wildcard?
        parts.last == Shark::Permissions.any_matcher
      end

      def to_s
        name
      end
    end
  end
end
