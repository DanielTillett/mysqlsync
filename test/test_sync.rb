require 'test-unit'
require 'mysqlsync'

class TestSync < Test::Unit::TestCase
  def self.startup
    # Variables
    dns_from  = 'h=127.0.0.1,P=3306,u=root'
    dns_to    = 'h=127.0.0.1,P=3306,u=root'

    from      = Mysqlsync::Sync.explode_dns(dns_from)
    to        = Mysqlsync::Sync.explode_dns(dns_to)

    @@con_from = Mysqlsync::Schema.new(from)
    @@con_to   = Mysqlsync::Schema.new(to)

    # Create databases
    sql_db_from = "CREATE DATABASE IF NOT EXISTS demo_from CHARACTER SET UTF8;"
    sql_db_to   = "CREATE DATABASE IF NOT EXISTS demo_to CHARACTER SET UTF8;"

    @@con_from.execute(sql_db_from)
    @@con_to.execute(sql_db_to)

    # Create tables:
    sql_table_a_from = <<-EOS
      CREATE TABLE IF NOT EXISTS demo_from.data (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        a INT,
        b BOOLEAN DEFAULT FALSE,
        c DECIMAL(4,2),
        d VARCHAR(10),
        e CHAR(1),
        f TIMESTAMP,
        g DATETIME
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    EOS

    sql_table_b_from = <<-EOS
      CREATE TABLE IF NOT EXISTS demo_from.pk (
        a INT NOT NULL,
        b INT NOT NULL
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    EOS

    sql_table_c_from = <<-EOS
      CREATE TABLE IF NOT EXISTS demo_from.schema (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        a INT DEFAULT 0,
        b BOOLEAN DEFAULT FALSE,
        c DECIMAL(4,2),
        d VARCHAR(10),
        e CHAR(1) NOT NULL DEFAULT 'E',
        f TIMESTAMP,
        g DATETIME
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    EOS

    sql_table_a_to = <<-EOS
      CREATE TABLE IF NOT EXISTS demo_to.data (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        a INT,
        b BOOLEAN DEFAULT FALSE,
        c DECIMAL(4,2),
        d VARCHAR(10),
        e CHAR(1),
        f TIMESTAMP,
        g DATETIME
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    EOS

    sql_table_b_to = <<-EOS
      CREATE TABLE IF NOT EXISTS demo_to.pk (
        a INT NOT NULL,
        b INT NOT NULL
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    EOS

    sql_table_c_to = <<-EOS
      CREATE TABLE IF NOT EXISTS demo_to.schema (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        a INT,
        b BOOLEAN DEFAULT TRUE,
        d VARCHAR(10),
        c DECIMAL(4,2),
        e CHAR(1),
        h DATETIME
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    EOS

    @@con_from.execute(sql_table_a_from)
    @@con_from.execute(sql_table_b_from)
    @@con_from.execute(sql_table_c_from)
    @@con_to.execute(sql_table_a_to)
    @@con_to.execute(sql_table_b_to)
    @@con_to.execute(sql_table_c_to)

    # Pupulate tables:
    sql_insert_from = <<-EOS
    INSERT INTO demo_from.data (id, a, b, c, d, e, f, g) VALUES
      (1, 12345, 1,   1, 'AAA', 'A', '2014-02-22 22:11:00', NULL),
      (2, 12345, 0, 1.2, 'BBB', 'B', '2014-02-22 22:11:00', NULL),
      (3, 12345, 0, 1.3, 'CCC', 'C', '2014-02-22 22:11:00', '2014-03-01 01:01:01'),
      (5, 12345, 1, 0.5, 'EEE', 'E', '2014-02-22 22:11:00', NULL);
    EOS

    sql_insert_to = <<-EOS
    INSERT INTO demo_to.data (id, a, b, c, d, e, f, g) VALUES
      (1, 12345, 1,   1, 'AAA', 'A', '2014-02-22 22:11:00', NULL),
      (2, 12345, 0, 1.2, 'BBB', 'B', '2014-02-22 22:11:00', NULL),
      (4, 12345, 1, 1.4, 'DDD', 'D', '2014-02-22 22:11:00', '2014-02-23 01:01:01'),
      (5, 12345, 1,   1, 'AAA', 'A', '2014-02-22 22:11:00', NULL);
    EOS

    @@con_from.execute(sql_insert_from)
    @@con_to.execute(sql_insert_to)

    dns_from  = 'h=127.0.0.1,P=3306,u=root,p=,d=demo_from'
    dns_to    = 'h=127.0.0.1,P=3306,u=root,p=,d=demo_to'

    # Initialize object to test:
    @@sync_data   = Mysqlsync::Sync.new(dns_from, dns_to, 'data')
    @@sync_pk     = Mysqlsync::Sync.new(dns_from, dns_to, 'pk')
    @@sync_schema = Mysqlsync::Sync.new(dns_from, dns_to, 'schema')
  end

  def test_01_is_not_equal_checksum
    assert_equal(false, @@sync_data.checksum)
  end

  def test_02_is_not_valid_schema
    assert_equal(false, @@sync_pk.valid_schema)
  end

  def test_03_is_valid_schema
    assert_equal(true, @@sync_data.valid_schema)
  end

  def test_04_delete
    # Get value.
    row_test  = @@sync_data.do_delete[0]
    row_match = "DELETE FROM `demo_to`.`data` WHERE id = 4;"

    # Apply change into table.
    @@con_to.execute(row_test)

    # Evaluate.
    assert_equal(row_test, row_match)
  end

  def test_05_update
    # Get value.
    row_test  = @@sync_data.do_update[0]
    row_match = "UPDATE `demo_to`.`data` SET a = 12345, b = 1, c = 0.5E0, d = 'EEE', e = 'E', f = '2014-02-22 22:11:00', g = NULL WHERE id = 5;"

    # Apply change into table.
    @@con_to.execute(row_test)

    # Evaluate.
    assert_equal(row_test, row_match)
  end

  def test_06_insert
    # Get value.
    row_test  = @@sync_data.do_insert[0]
    row_match = "INSERT INTO `demo_to`.`data`(`id`, `a`, `b`, `c`, `d`, `e`, `f`, `g`) VALUES (3, 12345, 0, 0.13E1, 'CCC', 'C', '2014-02-22 22:11:00', '2014-03-01 01:01:01');"

    # Apply change into table.
    @@con_to.execute(row_test)

    # Evaluate.
    assert_equal(row_test, row_match)
  end

  def test_07_is_equal_checksum
    assert_equal(true, @@sync_data.checksum)
  end

  def test_08_is_not_equal_table
    assert_equal(false, @@sync_schema.equal_table)
  end

  def test_09_alter_table_modify
    # Get value.
    row_test  = @@sync_schema.do_alter_table_modify
    row_match = ["ALTER TABLE `demo_to`.`schema` MODIFY COLUMN a int(11) NULL DEFAULT 0 AFTER id;",
                 "ALTER TABLE `demo_to`.`schema` MODIFY COLUMN b tinyint(1) NULL DEFAULT 0 AFTER a;",
                 "ALTER TABLE `demo_to`.`schema` MODIFY COLUMN c decimal(4,2) NULL AFTER b;",
                 "ALTER TABLE `demo_to`.`schema` MODIFY COLUMN d varchar(10) NULL AFTER c;",
                 "ALTER TABLE `demo_to`.`schema` MODIFY COLUMN e char(1) NOT NULL DEFAULT 'E' AFTER d;",
                 "ALTER TABLE `demo_to`.`schema` ADD COLUMN f timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP AFTER e;",
                 "ALTER TABLE `demo_to`.`schema` ADD COLUMN g datetime NULL AFTER f;"]

    # Apply change into table.
    row_test.each { |alter|
      # puts alter
      @@con_to.execute(alter)
    }

    # Evaluate.
    assert_equal(row_test, row_match)
  end

  def test_10_alter_table_remove
    # Get value.
    row_test  = @@sync_schema.do_alter_table_remove[0]
    row_match = "ALTER TABLE `demo_to`.`schema` DROP COLUMN h;"

    # Apply change into table.
    @@con_to.execute(row_test)

    # Evaluate.
    assert_equal(row_test, row_match)
  end

  def test_11_is_equal_table
    assert_equal(true, @@sync_schema.equal_table)
  end

  def self.shutdown
    sql_db_fom = 'DROP DATABASE IF EXISTS demo_from;'
    sql_db_to  = 'DROP DATABASE IF EXISTS demo_to;'

    @@con_from.execute(sql_db_fom)
    @@con_to.execute(sql_db_to)

    @@con_from = nil
    @@con_to   = nil
  end
end