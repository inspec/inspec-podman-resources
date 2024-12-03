# frozen_string_literal: true

require "helper"

class TrueEqualsTrueTest < Minitest::Test
  def test_true_equals_true
    assert_equal true, true
  end
end
