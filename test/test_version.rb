require 'test-unit'
require 'mysqlsync'

class TestVersion < Test::Unit::TestCase
  def test_version
    assert_not_nil(Mysqlsync::VERSION)
  end
end