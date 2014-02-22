require 'test-unit'
require 'mysqlsync'

class Test01 < Test::Unit::TestCase
  def test_version
    assert_not_nil(Mysqlsync::VERSION)
  end
end