# frozen_string_literal: true

if ENV["CI_ENABLE_COVERAGE"]
  require "simplecov/no_defaults"
  require_relative "../helpers/simplecov_minitest"
  SimpleCov.start do
    add_filter "/test/"
    add_group "Resources", ["lib/inspec-podman-resources/resources"]
  end
end

require "minitest/autorun"
require "minitest/unit"
require "minitest/pride"
require "inspec/resource"
require "mocha/minitest"

module Minitest
  class Test
    def setup
      # TODO: Setup logic
    end
  end
end
