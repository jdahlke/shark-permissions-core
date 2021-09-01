# frozen_string_literal: true

require 'active_support/all'

require 'shark/permissions/changes'
require 'shark/permissions/resource'
require 'shark/permissions/rule'
require 'shark/permissions/list'

module Shark
  module Permissions
    mattr_accessor :any_matcher, :delimiter

    def self.configure
      yield self
    end

    configure do |config|
      config.delimiter   = '::'
      config.any_matcher = '*'
    end
  end
end
