require 'test-unit'
require 'mysqlsync'

class Test01 < Test::Unit::TestCase
  def test0101
    assert_not_nil(Mysqlsync::VERSION)
  end
end