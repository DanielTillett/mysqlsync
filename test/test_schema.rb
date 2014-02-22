require 'test/unit'
require 'mysqlsync'

class SchemaTest < Test::Unit::TestCase
  def setup
    # Variables
    dns_from  = 'h=127.0.0.1,P=3306,u=root,p='
    dns_to    = 'h=127.0.0.1,P=3306,u=root,p='

    from      = Mysqlsync::Sync.explode_dns(dns_from)
    to        = Mysqlsync::Sync.explode_dns(dns_to)

    @con_from = Mysqlsync::Schema.new(from)
    @con_to   = Mysqlsync::Schema.new(to)

    # Create databases
    @con_from.execute(sql_database('demo_from'))
    @con_to.execute(sql_database('demo_to'))

    # Create tables:
    @con_from.execute(sql_table('demo_from'))
    @con_to.execute(sql_table('demo_to'))

    # Pupulate tables:
    @con_from.execute(sql_insert_from)
    @con_from.execute(sql_insert_to)

    dns_from  = 'h=127.0.0.1,P=3306,u=root,p=,d=demo_from'
    dns_to    = 'h=127.0.0.1,P=3306,u=root,p=,d=demo_to'

    # Initialize object to test:
    @sync = Mysqlsync::Sync.new(dns_from, dns_to, 'a')
  end

  def sql_database(name)
    "CREATE DATABASE IF NOT EXISTS #{name} CHARACTER SET UTF8;"
  end

  def sql_table(database)
    <<-SQL
      CREATE TABLE IF NOT EXISTS `#{database}`.a (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        a INT,
        b BOOLEAN DEFAULT FALSE,
        c DECIMAL(4,2),
        d VARCHAR(10),
        e CHAR(1),
        f TIMESTAMP,
        g DATETIME
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    SQL
  end

  def sql_insert_from()
    <<-SQL
    INSERT INTO demo_from.a VALUES
      (1, 12345, 1,   1, 'AAA', 'A', '2014-02-22 22:11:00', NULL),
      (2, 12345, 0, 1.2, 'BBB', 'B', '2014-02-22 22:11:00', NULL),
      (3, 12345, 0, 1.3, 'CCC', 'C', '2014-02-22 22:11:00', '2014-03-01 01:01:01'),
      (5, 12345, 1, 0.5, 'EEE', 'E', '2014-02-22 22:11:00', NULL);
    SQL
  end

  def sql_insert_to()
    <<-SQL
    INSERT INTO demo_to.a VALUES
      (1, 12345, 1,   1, 'AAA', 'A', '2014-02-22 22:11:00', NULL),
      (2, 12345, 0, 1.2, 'BBB', 'B', '2014-02-22 22:11:00', NULL),
      (4, 12345, 1, 1.4, 'DDD', 'D', '2014-02-22 22:11:00', '2014-02-23 01:01:01'),
      (5, 12345, 1,   1, 'AAA', 'A', '2014-02-22 22:11:00', NULL);
    SQL
  end

  def teardown
    sql_db_fom = 'DROP DATABASE IF EXISTS demo_from;'
    sql_db_to  = 'DROP DATABASE IF EXISTS demo_to;'

    @con_from.execute(sql_db_fom)
    @con_to.execute(sql_db_to)

    @con_from = nil
    @con_to = nil
  end

  def test_step_1_checksum
    assert_equal(false, @sync.checksum)
  end

  def test_step_2_valid_schema
    assert_equal(true, @sync.valid_schema)
  end

  def test_step_3_delete
    row_test  = @sync.do_delete[0]
    row_match = "DELETE FROM `demo_to`.`a` WHERE id = 4;"

    assert_equal(row_test, row_match)
  end

  def test_step_4_update
    row_test  = @sync.do_update[0]
    row_match = "UPDATE `demo_to`.`a` SET a = 12345, b = 1, c = 0.5E0, d = 'EEE', e = 'E', f = '2014-02-22 22:11:00', g = NULL WHERE id = 5;"

    assert_equal(row_test, row_match)
  end

  def test_step_5_insert
    row_test  = @sync.do_insert[0]
    row_match = "INSERT INTO `demo_to`.`a`(`id`, `a`, `b`, `c`, `d`, `e`, `f`, `g`) VALUES (3, 12345, 0, 0.13E1, 'CCC', 'C', '2014-02-22 22:11:00', '2014-03-01 01:01:01');"

    assert_equal(row_test, row_match)
  end
end