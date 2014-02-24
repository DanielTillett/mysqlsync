require 'mysqlsync/schema'

module Mysqlsync
  class Sync
    def initialize(from, to, table)
      @table = table
      @from  = Sync.explode_dns(from)
      @to    = Sync.explode_dns(to)
      @from  = Schema.new(@from, @table)
      @to    = Schema.new(@to, @table)

      if valid_schema
        @from_columns = @from.get_columns
        @from_ids     = @from.get_ids
        @from_md5s    = @from.get_md5s
        @to_columns   = @to.get_columns
        @to_ids       = @to.get_ids
        @to_md5s      = @to.get_md5s
      end
    end

    def self.explode_dns(options)
      options.split(',')
             .map{ |c| c.split('=', 2) }
             .inject({}) { |m, (key,value)|
              case key.to_sym
                when :h
                  key = :host
                when :u
                  key = :user
                when :p
                  key = :password
                when :P
                  key = :port
                when :d
                  key = :database
              end
              m[key] = value; m
            }
    end

    def checksum
      (@from.get_checksum == @to.get_checksum)
    end

    def valid_schema
      !@from.get_primary_key.empty?
      !@to.get_primary_key.empty?
    end

    def get_dump_head
      puts @to.get_dump_head
    end

    def get_dump_bottom
      puts @to.get_dump_bottom
    end

    def equal_table
      (@from.get_desc_table == @to.get_desc_table)
    end

    def do_alter_table_modify
      left   = @from.get_desc_table
      right  = @to.get_desc_table
      diff   = left - right

      diff.map { |alter|
        @to.get_alter_table(alter, right, left)
      }
    end

    def do_alter_table_remove
      left   = @from.get_desc_table
      right  = @to.get_desc_table
      remove = right.map{|k,v| k } - left.map{|k,v| k }

      remove.map { |column|
        @to.get_drop_column(column)
      }
    end

    def do_insert()
      # Remove Any Elements from Array 1 that are contained in Array 2.(Difference)
      ids     = @from_ids - @to_ids
      columns = @from.get_columns()
      inserts = @from.get_data(ids)

      if !inserts.nil?
        inserts.map { |insert|
          @to.get_insert(columns, insert)
        }
      end
    end

    def do_update()
      # Get Common Elements between Two Arrays(Intersection)
      left  = (@from_md5s - @to_md5s).map{|k,v| k }
      right = (@to_md5s   - @from_md5s).map{|k,v| k }
      diff  = left & right
      pk    = @from.get_primary_key()

      values = @from.get_data(diff)
      if values.kind_of?(Array)
        values.map { |update|
          @to.get_update(update, pk)
        }
      end
    end

    def do_delete()
      # Remove Any Elements from Array 1 that are contained in Array 2.(Difference)
      ids     = @to_ids - @from_ids
      id      = @to.get_primary_key()
      columns = @to.get_columns()
      deletes = @to.get_data(ids)

      if !deletes.nil?
        deletes.map { |delete|
          @to.get_delete(id, delete)
        }
      end
    end
  end
end
