# frozen_string_literal: true

module Shark
  module Permissions
    class List
      delegate :[], :[]=, :empty?, :size, to: :rules
      delegate :key?, :keys, :values, :each, :each_with_object, to: :rules

      attr_reader :rules

      def initialize(rules = {})
        case rules
        when Shark::Permissions::List
          @rules = to_permission_rules(rules.as_json)
        when Hash
          @rules = to_permission_rules(rules)
        else
          raise ArgumentError, 'Rules must be a subtype of Hash'
        end
      end

      # @return [Boolean]
      # @api public
      def ==(other)
        rules == other.rules
      end

      # @api public
      def <<(rule)
        @rules[rule.resource] = rule
      end

      # @return [Array]
      # @api public
      def map(&block)
        rules.values.map(&block)
      end

      def changes
        changed_rules = rules.select { |_key, rule| rule.changed? }.to_h
        self.class.new(changed_rules)
      end

      # Returns a new Permissions::List with same rules.
      #
      # @return [Permissions::List]
      # @api public
      def clone
        cloned_rules = {}
        rules.each { |k, rule| cloned_rules[k] = rule.clone }

        self.class.new(cloned_rules)
      end

      # Returns a new Permissions::List without any rules that have no privileges.
      #
      # @return [Permissions::List]
      # @api public
      def compact
        new_rules = {}

        rules.keys.sort.each do |k|
          rule = rules[k].clone
          new_rules[k] = rule unless rule.empty?
        end

        self.class.new(new_rules)
      end

      def delete(key)
        case key
        when String
          rules.delete(key)
        when Permissions::Rule
          rules.delete(key.resource)
        else
          raise ArgumentError, 'Argument must be a String or Permissions::Rule'
        end
      end

      def select(names)
        filtered_rules = {}

        Array(names).each do |filter_name|
          filter_resource = Permissions::Resource.new(filter_name)
          rules.each do |name, rule|
            next unless filter_resource.super_resource_of?(name)

            filtered_rules[rule.resource] = rule.clone
          end
        end

        self.class.new(filtered_rules)
      end
      alias filter select

      def reject(names)
        filtered_rules = {}

        rejected_keys = select(names).keys
        rules.each do |name, rule|
          next if rejected_keys.include?(name)

          filtered_rules[rule.resource] = rule.clone
        end

        self.class.new(filtered_rules)
      end

      # @param other_list [Shark::Permissions::List]
      # @return [Hash]
      # @api public
      def merge(other_list)
        clone.merge!(other_list)
      end

      # Merges another list into this list. Allowed privileges are not removed.
      # Changes are not tracked.
      #
      # @param other_list [Shark::Permissions::List]
      # @return [Hash]
      # @api public
      def merge!(other_list)
        other_list.each do |resource, rule|
          if rules.key?(resource)
            privileges = rules[resource].privileges
            rule.privileges.each { |k, v| privileges[k] = privileges[k] || v }
          else
            rules[resource] = rule.clone
          end
        end

        self
      end

      # Updates this list with rules from another list.
      # All affected rules are updated and changes are tracked.
      #
      # @param other_list [Shark::Permissions::List]
      # @return [Hash]
      # @api public
      def update(other_list)
        other_list.each do |resource, other_rule|
          rules[resource] = Permissions::Rule.new(resource: resource) unless rules.key?(resource)
          rules[resource].update(other_rule)
        end

        self
      end

      # @example:
      #   list.privileges(:paragraph, :contracts)
      #   # => { 'admin' => true, 'edit' => true }
      #
      # @return [Hash]
      # @api public
      def privileges(*resources)
        matching_resources = matching_resources(*resources)
        privileges_set = Set.new

        matching_resources.each do |name|
          rule = rules[name]

          next unless rule

          case rule.effect
          when 'ALLOW'
            privileges_set.merge(rule.privileges_as_array)
          when 'DENY'
            privileges.subtract(rule.privileges_as_array)
          end
        end

        privileges_set.map { |k| [k, true] }.to_h
      end

      # @example:
      #   list.authorized?(:admin, :paragraph, :contracts)
      #   # => true
      #   list.authorized?([:read, :write], :datenraum, :berlin)
      #   # => false
      #
      # @return [Boolean]
      # @api public
      def authorized?(privilege, *resources)
        if privilege == Shark::Permissions.any_matcher
          privileges(*resources).present?
        else
          privilege_array = Array(privilege).map(&:to_s)
          privileges_for_resource = privileges(*resources)
          privilege_array.any? { |p| privileges_for_resource.fetch(p, false) }
        end
      end

      # @example:
      #   list.subresource_authorized?(:admin, :paragraph, :contracts)
      #   # => true
      #
      # @return [Boolean]
      # @api public
      def subresource_authorized?(privilege, *resources)
        authorized?(privilege, *resources, Shark::Permissions.any_matcher)
      end

      # Correctly set privileges for subresources.
      #
      # @return [Permissions::List]
      # @api public
      def set_inherited_privileges!
        rules.each do |resource, rule|
          privileges = privileges(resource)
          privileges.each { |k, v| rule.privileges[k] = v if rule.privileges.key?(k) }
        end

        self
      end

      # Returns new list without inherited privileges and empty rules.
      #
      # @return [Permissions::List]
      # @api public
      def remove_inherited_rules
        new_list = self.class.new({})

        rules.keys.sort.each do |name|
          new_rule = Permissions::Rule.new(resource: name)
          parent = new_rule.parent

          rules[name].privileges.each do |k, v|
            new_rule.privileges[k] = v if v && !new_list.authorized?(k, parent)
          end

          new_list << new_rule unless new_rule.empty?
        end

        new_list
      end

      # @return [Hash]
      # @api public
      def as_json(*args)
        rules.as_json(*args)
      end

      # For Deserializaton
      #
      # @return [Shark::Permissions::List]
      # @api public
      def self.load(json)
        if json.nil?
          new
        else
          new(JSON.parse(json))
        end
      end

      # For Serializaton
      #
      # @return [String]
      # @api public
      def self.dump(list)
        list&.to_json
      end

      private

      def to_permission_rules(rules)
        return {} if rules.blank?

        if rules.values.first.is_a?(Permissions::Rule)
          # do nothing
        else
          rules = rules.map { |k, v| [k.to_s, Permissions::Rule.new(v)] }
          rules = Hash[rules]
        end

        rules
      end

      def matching_resources(*resources)
        resource = Resource.new(resources)
        result = resource.ancestors_and_self

        if resource.wildcard?
          result = resource.ancestors
          subresources = rules.keys.select { |name| resource.super_resource_of?(name) }
          result.concat(subresources)
        end

        result
      end
    end
  end
end
