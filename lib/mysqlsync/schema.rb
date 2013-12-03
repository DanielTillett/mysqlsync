require 'rubygems'
require 'mysql2'
require 'time'

module Mysqlsync
  class Schema
<<<<<<< HEAD
    def initialize(type, host, table, increment)
      @type      = type
      @host      = host[:host]
      @username  = host[:user]
      @password  = host[:password]
      @database  = host[:database]
      @port      = host[:port].to_i
      @table     = table
      @increment = increment
      @describe  = get_desc_table
      @id        = get_primary_key();
      @columns   = get_columns()

      @increment[:columns] = "`#{@increment[:columns]}`"

      # @increment[:value] = get_increment_value + @increment[:value].to_i;
=======
    def initialize(host, table, increment)
      @host     = host[:host]
      @username = host[:user]
      @password = host[:password]
      @database = host[:database]
      @port     = host[:port].to_i
      @table    = table
      @describe = get_desc_table
>>>>>>> f839aef37abbe17e29a437bd7e054a76d2cc32a3
    end

    def execute(sql)
      @mysql = Mysql2::Client.new(host: @host,
                                  username: @username,
                                  password: @password,
                                  database: @database,
                                  port: @port,
                                  database_timezone: :local,
                                  application_timezone: :local)
      @mysql.query(sql)
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
      sql = <<SQL
SELECT COLUMN_NAME,
       COLUMN_TYPE,
       IS_NULLABLE,
       COLUMN_DEFAULT,
       EXTRA,
       ORDINAL_POSITION
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_schema = '#{@database}'
  AND table_name   = '#{@table}';
SQL

      execute(sql).each(as: :array)
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

      execute(sql).each(as: :array).join(',')
    end

    def add_increment_column()
      if @type == :from && !@increment[:columns].nil? && @increment[:columns].include?(@id)
        "#{@id} + #{@increment[:value]}"
      else
        @id
      end
    end

    def add_increment_value(column)
      if @type == :from && !@increment[:columns].nil? && @increment[:columns].include?(column)
        column = "#{column} + #{@increment[:value]}"
      end
      column
    end

    # def get_increment_value
    #   columns = @increment[:columns].split(',')
    #                                 .collect { |column| "MAX(#{column})" }
    #                                 .join(',')
    #   if @increment[:columns].split(',').count > 1
    #     columns = "GREATEST(#{columns})"
    #   end

    #   sql = "SELECT #{columns} AS 'max' FROM #{get_table_path};"

    #   execute(sql).first['max'].to_i
    # end

    # Use this method only for get id's for DELETE and INSERT.
    def get_ids(action)
      if @type == :to
        id    = @id
        where = " WHERE #{@id} >= #{@increment[:value]}"
      else
        id    = "#{@id} + #{@increment[:value]}"
        where = ""
      end

      if !id.empty?
        sql = "SELECT MD5(#{id}) AS id FROM #{get_table_path}#{where};"

        execute(sql).each(as: :array)
      end
    end

    # Use this method only for get id's for UPDATE.
    def get_md5s
      columns = @columns

      if @type == :to
        id    = @id
        where = " WHERE #{@id} >= #{@increment[:value]}"
      else
        id     = "#{@id} + #{@increment[:value]}"
        columns = columns.map { |column| (column == "`#{@id}`")? id : column}
        where  = ""
      end

      # puts "\n\n"
      # id      = get_primary_key();
      # p columns.map { |column| if column == "`#{id_tmp}`" then "`#{id}`" else id end }




      columns = columns.map { |column| "COALESCE(#{column}, '#{column}')"}
      sql     = "SELECT MD5(CONCAT(#{id})) AS id, MD5(CONCAT(#{columns.join(', ')})) AS md5 FROM #{get_table_path}#{where};"

      execute(sql).each(as: :array)
    end

    # Use this method for INSERT, UPDATE and DELETE.
    def get_data(ids)
      if !ids.empty?
        select  = Array.new
        @columns.each do |column|
          case get_datatype(column)
            when 'DATETIME', 'TIMESTAMP'
              select << remove_timezone(column)
            else
              select << add_increment_value(column)
          end
        end

        # Insert
        id = add_increment_column

        # Delete
        # id = @id

        sql  = 'SELECT '
        sql << select.join(', ')
        sql << ' FROM '
        sql << get_table_path
        sql << " WHERE MD5(CONCAT(#{id})) IN ("
        sql << ids.collect {|e| "#{value(e)}" }.join(',')
        sql << ');'

        execute(sql).each
      end
    end

    def get_alter_table(alter, right, left)
      column  = alter[0]
      type    = alter[1]
      action  = (right.any? {|i| i.first == alter.first})? ' MODIFY' : ' ADD'
      notnull = (!alter[2] == 'NO')? ' NOT NULL' : ' NULL'
      default = (!alter[3].nil?)? " DEFAULT #{alter[3]}" : ''
      ai      = (alter[4].include? 'auto_increment')? ' AUTO_INCREMENT' : ''
      index   = left.each_index.select{|i| left[i] == alter}.first
      after   = left[((index > 0)? index - 1 : 0)].first
      after   = (index > 0)? " AFTER #{after}" : ' FIRST'

      sql  = 'ALTER TABLE '
      sql << get_table_path
      sql << action
      sql << ' COLUMN '
      sql << column
      sql << ' '
      sql << type
      sql << notnull
      sql << default
      sql << ai
      sql << after
      sql << ';'
    end

    def get_insert(columns, values)
      sql  = 'INSERT INTO '
      sql << get_table_path
      sql << '('
      sql << columns.join(', ')
      sql << ') VALUES ('
      sql << values.map{ |key, value| value(value, key) }.join(', ')
      sql << ');'
    end

    def get_update(values, pk)
      update = values.map{ |key, value|
                          "#{key} = #{value(value, key)}" if key != pk
                         }
                     .reject{ |k, v| k.nil? }
                     .join(', ')

      sql  = 'UPDATE '
      sql << get_table_path
      sql << ' SET '
      sql << update
      sql << ' WHERE '
      sql << pk
      sql << ' = '
      sql << values[pk].to_s
      sql << ';'
    end

    def get_delete(pk, values)
      values.map { |key, value| value(value, key) }

      if pk.split(',').count > 1
        id = pk.split(',').collect{|pk| "#{pk} = #{values[pk]}" }.join(' AND ')
      else
        id = "#{pk} = #{values[pk].to_s}"
      end

      sql  = 'DELETE FROM '
      sql << get_table_path
      sql << ' WHERE '
      sql << id
      sql << ';'
    end

    def get_drop_column(name)
      sql  = 'ALTER TABLE '
      sql << get_table_path
      sql << ' DROP COLUMN '
      sql << name
      sql << ';'
    end

    def is_a_number?(value)
      /^[+-]?\d+?(\.\d+)?$/ === value.to_s
    end

    def remove_timezone(timestamp)
      "SUBSTRING(#{timestamp}, 1, 19) AS #{timestamp}"
    end

    def get_datatype(column)
      @describe.each do |c|
        if "`#{c.first}`" == column
          return c[1].gsub(/\(\d+(\,\d+)?\)/, '').upcase
        end
      end
    end

    def value(value, key = nil)
      if value.kind_of?(Array)
        value(value.first, key)
      else
        if value.nil?
          'NULL'
        elsif key.nil?
          if !is_a_number?(value)
            "'#{value}'"
          else
            value
          end
        else
          case get_datatype(key)
          when 'INT', 'TINYINT', 'SMALLINT', 'MEDIUMINT', 'BIGINT', 'FLOAT', 'DOUBLE', 'DECIMAL'
            value
          when 'DATE', 'DATETIME', 'TIMESTAMP', 'TIME', 'YEAR'
            "'#{value}'"
          when 'CHAR', 'VARCHAR', 'BLOB', 'TEXT', 'TINYBLOB', 'TINYTEXT', 'MEDIUMBLOB', 'MEDIUMTEXT', 'LONGBLOB', 'LONGTEXT', 'ENUM'
            value(@mysql.escape(value))
          else
            value(value)
          end
        end
      end
    end

    def get_table_path
      "`#{@database}`.`#{@table}`"
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
LOCK TABLES #{get_table_path} WRITE;
/*!40000 ALTER TABLE #{get_table_path} DISABLE KEYS */;
HEAD
    end

    def get_dump_bottom
      <<BOTTOM
/*!40000 ALTER TABLE #{get_table_path} ENABLE KEYS */;
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
