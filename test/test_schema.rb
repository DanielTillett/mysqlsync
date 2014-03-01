require 'test-unit'
require 'mysqlsync'

class TestSchema < Test::Unit::TestCase
  def self.startup
    # Variables
    dns_from   = 'h=127.0.0.1,P=3306,u=root,d=demo_from'
    from       = Mysqlsync::Sync.explode_dns(dns_from)
    @@con_from = Mysqlsync::Schema.new(from, 'a')
  end

  def test_table_path
    test = @@con_from.get_table_path
    assert_equal(test, '`demo_from`.`a`')
  end

  def self.shutdown
  end
end