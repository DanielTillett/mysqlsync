require 'rubygems'
require 'mysql2'
require 'time'

module Mysqlsync
  class Schema
    def initialize(host, table)
      @host     = host[:host]
      @username = host[:username]
      @password = host[:password]
      @database = host[:database]
      @port     = host[:port]
      @table    = table
    end

    def execute(sql)
      mysql = Mysql2::Client.new(host: @host,
                                 username: @username,
                                 password: @password,
                                 database: @database,
                                 port: @port,
                                 database_timezone: :local,
                                 application_timezone: :local)
      mysql.query(sql)
    end

    def get_tables()
      sql = <<SQL
SELECT table_name
FROM information_schema.tables
WHERE table_schema = '#{@database}'
  AND table_type   = 'BASE TABLE'
ORDER BY table_name;
SQL

      execute(sql).map { |table| "`#{table['table_name']}`" }
    end

    def get_desc_table()
      sql = "DESC `#{@database}`.#{@table};"

      execute(sql).each(:as => :array)
    end

    def get_columns()
      sql = <<SQL
SELECT COLUMN_NAME
FROM information_schema.columns
WHERE table_schema = '#{@database}'
  AND table_name   = '#{@table}';
SQL

      execute(sql).map { |column| "`#{column['COLUMN_NAME']}`" }
    end

    def get_primary_key()
      sql = <<SQL
SELECT COLUMN_NAME
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = '#{@database}'
  AND TABLE_NAME   = '#{@table}'
  AND COLUMN_KEY   = 'PRI';
SQL

      execute(sql).first['COLUMN_NAME']
    end

    def get_primary_keys()
      id  = get_primary_key();
      sql = "SELECT DISTINCT #{id} FROM #{@database}.#{@table};"

      execute(sql).map { |column| column[id]}
    end

    def get_ids
      id  = get_primary_key();
      sql = "SELECT #{id} AS id FROM `#{@database}`.#{@table};"

      execute(sql).each(:as => :array)
    end

    def get_data(ids)
      if !ids.empty?
        id      = get_primary_key();
        table   = get_desc_table()
        columns = Array.new
        table.each do |field|
          case field[1]
          when 'datetime'
            columns << "SUBSTRING(#{field[0]}, 1, 19) AS #{field[0]}"
          when 'timestamp'
            columns << "SUBSTRING(#{field[0]}, 1, 19) AS #{field[0]}"
          else
            columns << field[0]
          end
        end

        sql  = 'SELECT '
        sql << columns.join(', ')
        sql << ' FROM '
        sql << "#{@database}.#{@table}"
        sql << ' WHERE '
        sql <<  id
        sql << ' IN ('
        sql << ids.join(', ')
        sql << ');'

        # puts sql

        execute(sql).each
      end
    end

    def get_insert(columns, values)
      sql  = 'INSERT INTO '
      sql << "#{@database}.#{@table}"
      sql << '('
      sql << columns.join(', ')
      sql << ') VALUES ('
      sql << values.join(', ')
      sql << ');'
    end

    def get_update(values, pk, id)
      sql  = 'UPDATE '
      sql << "#{@database}.#{@table}"
      sql << ' SET '
      sql << values
      sql << ' WHERE '
      sql << pk
      sql << ' = '
      sql << id
      sql << ';'
    end

    def get_delete(pk, id)
      sql  = 'DELETE FROM '
      sql << "#{@database}.#{@table}"
      sql << ' WHERE '
      sql << pk
      sql << ' = '
      sql << id
      sql << ';'
    end

    def get_drop_column(name)
      sql  = 'ALTER TABLE '
      sql << "#{@database}.#{@table}"
      sql << ' DROP COLUMN '
      sql << name
      sql << ';'
    end

    def get_md5s
      id      = get_primary_key();
      columns = get_columns()

      md5 = columns.map { |column| "COALESCE(#{column}, '#{column}')"}

      sql = "SELECT #{id} AS id, MD5(CONCAT(#{md5.join(', ')})) AS md5 FROM #{@database}.#{@table};"

      execute(sql).each(:as => :array)
    end

    def get_checksum
      sql = "CHECKSUM TABLE #{@database}.#{@table};"

      execute(sql).each(:as => :array).first[1]
    end

    def is_a_number?(value)
      /^[+-]?\d+?(\.\d+)?$/ === value.to_s
    end

    def value(value)
      if value.nil?
        value = 'NULL'
      else
        !is_a_number?(value)? "'#{value}'" : value
      end
    end

    def get_dump_head
      <<HEAD
/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
LOCK TABLES `#{@database}`.`#{@table}` WRITE;
/*!40000 ALTER TABLE `#{@database}`.`#{@table}` DISABLE KEYS */;
HEAD
    end

    def get_dump_bottom
      <<BOTTOM
/*!40000 ALTER TABLE `#{@database}`.`#{@table}` ENABLE KEYS */;
UNLOCK TABLES;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
-- Sync completed on #{Time.now.utc.iso8601}
BOTTOM
    end
  end
end