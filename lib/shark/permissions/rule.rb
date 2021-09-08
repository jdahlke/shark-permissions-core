# frozen_string_literal: true

module Shark
  module Permissions
    class Rule
      attr_accessor :resource, :effect, :privileges, :title
      attr_reader :changes

      delegate :parent, to: :resource_model

      def initialize(args)
        symbol_args = args.symbolize_keys

        @resource = symbol_args.fetch(:resource)
        @privileges = symbol_args[:privileges] || {}
        normalize_privileges(@privileges)
        @effect = symbol_args[:effect] || 'ALLOW'
        @title = symbol_args[:title]
        @changes = Changes.new
      end

      def update(other)
        if resource != other.resource
          raise ArgumentError, "Trying to update different resource: got #{other.resource}, " \
            "but expected #{resource}"
        end

        other.privileges.each do |k, v|
          next if privileges[k] == v

          old = privileges[k]
          privileges[k] = v

          next if old == 'inherited'

          changes.add_privilege(k, old || false, v)
        end

        self
      end

      def changed?
        changes.present?
      end

      def clone
        self.class.new(as_json)
      end

      def empty?
        privileges.blank?
      end

      def resource_model
        Resource.new(resource)
      end

      def privileges_as_array
        privileges.select { |_, v| v == true }.keys
      end

      # @return Boolean
      # @api public
      def ==(other)
        resource == other.resource && effect == other.effect && privileges == other.privileges
      end

      def as_json(*_args)
        json = {
          'resource' => resource,
          'privileges' => privileges,
          'effect' => effect,
          'parent' => parent
        }
        json['title'] = title if title.present?

        json
      end

      private

      def normalize_privileges(privileges)
        privileges.each do |k, v|
          privileges[k] = case v
                          when 'inherited'
                            'inherited'
                          when true, 'true', 1
                            true
                          when false, 'false', 0
                            false
                          else
                            false
                          end
        end

        @privileges = privileges.stringify_keys
      end
    end
  end
end
