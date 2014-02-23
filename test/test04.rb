require 'test-unit'
require 'mysqlsync'

class Test04 < Test::Unit::TestCase
  def self.startup
    # Variables
    dns   = 'h=127.0.0.1,P=3306,u=root'
    from  = Mysqlsync::Sync.explode_dns(dns)
    @@con = Mysqlsync::Schema.new(from)

    # Create databases
    sql_db = "CREATE DATABASE IF NOT EXISTS demo CHARACTER SET UTF8;"

    @@con.execute(sql_db)

    # Create tables:
    sql_table = <<-EOS
      CREATE TABLE IF NOT EXISTS demo.a (
        a INT DEFAULT 0,
        b INT NOT NULL,
        c INT NOT NULL
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    EOS

    @@con.execute(sql_table)

    dns = 'h=127.0.0.1,P=3306,u=root,d=demo'

    # Initialize object to test:
    @@sync = Mysqlsync::Sync.new(dns, dns, 'a')
  end

  def test_0401
    assert_equal(false, @@sync.valid_schema)
  end

  def self.shutdown
    sql_db = 'DROP DATABASE IF EXISTS demo;'

    @@con.execute(sql_db)

    @@con = nil
  end
end