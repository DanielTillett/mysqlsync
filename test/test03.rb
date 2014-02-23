require 'test-unit'
require 'mysqlsync'

class Test03 < Test::Unit::TestCase
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
    sql_table_from = <<-EOS
      CREATE TABLE IF NOT EXISTS demo_from.a (
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

    sql_table_to = <<-EOS
      CREATE TABLE IF NOT EXISTS demo_to.a (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        a INT,
        b BOOLEAN DEFAULT TRUE,
        d VARCHAR(10),
        c DECIMAL(4,2),
        e CHAR(1),
        h DATETIME
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    EOS

    @@con_from.execute(sql_table_from)
    @@con_to.execute(sql_table_to)

    dns_from  = 'h=127.0.0.1,P=3306,u=root,p=,d=demo_from'
    dns_to    = 'h=127.0.0.1,P=3306,u=root,p=,d=demo_to'

    # Initialize object to test:
    @@sync = Mysqlsync::Sync.new(dns_from, dns_to, 'a')
  end

  def test_0301
    assert_equal(false, @@sync.equal_table)
  end

  def test_0302
    # Get value.
    row_test  = @@sync.do_alter_table_modify
    row_match = ["ALTER TABLE `demo_to`.`a` MODIFY COLUMN a int(11) NULL DEFAULT 0 AFTER id;",
                 "ALTER TABLE `demo_to`.`a` MODIFY COLUMN b tinyint(1) NULL DEFAULT 0 AFTER a;",
                 "ALTER TABLE `demo_to`.`a` MODIFY COLUMN c decimal(4,2) NULL AFTER b;",
                 "ALTER TABLE `demo_to`.`a` MODIFY COLUMN d varchar(10) NULL AFTER c;",
                 "ALTER TABLE `demo_to`.`a` MODIFY COLUMN e char(1) NOT NULL DEFAULT 'E' AFTER d;",
                 "ALTER TABLE `demo_to`.`a` ADD COLUMN f timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP AFTER e;",
                 "ALTER TABLE `demo_to`.`a` ADD COLUMN g datetime NULL AFTER f;"]

    # Apply change into table.
    row_test.each { |alter|
      # puts alter
      @@con_to.execute(alter)
    }

    # Evaluate.
    assert_equal(row_test, row_match)
  end

  def test_0303
    # Get value.
    row_test  = @@sync.do_alter_table_remove[0]
    row_match = "ALTER TABLE `demo_to`.`a` DROP COLUMN h;"

    # Apply change into table.
    @@con_to.execute(row_test)

    # Evaluate.
    assert_equal(row_test, row_match)
  end

  def test_0304
    assert_equal(true, @@sync.equal_table)
  end

  def self.shutdown
    sql_db_fom = 'DROP DATABASE IF EXISTS demo_from;'
    sql_db_to  = 'DROP DATABASE IF EXISTS demo_to;'

    @@con_from.execute(sql_db_fom)
    @@con_to.execute(sql_db_to)

    @@con_from = nil
    @@con_to = nil
  end
end