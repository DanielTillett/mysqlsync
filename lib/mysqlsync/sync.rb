require 'mysqlsync/schema'

module Mysqlsync
  class Sync
    def initialize(from, to, table)
      $from  = explode_dns(from)
      $to    = explode_dns(to)
      $table = table
      @from  = Schema.new($from, $table)
      @to    = Schema.new($to, $table)

      if valid_schema
        $from_columns = @from.get_columns
        $from_ids     = @from.get_ids
        $from_md5s    = @from.get_md5s
        $to_columns   = @to.get_columns
        $to_ids       = @to.get_ids
        $to_md5s      = @to.get_md5s
      end
    end

    def explode_dns(options)
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
      if @from.get_checksum == @to.get_checksum
        puts "Both tables are equal."
        exit 0
      else
        puts "Both tables are NOT equal."
        exit 1
      end
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

    def do_modify_table
      left   = @from.get_desc_table
      right  = @to.get_desc_table
      diff   = left - right
      remove = right.map{|k,v| k } - left.map{|k,v| k }

      diff.each do |alter|
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
        sql << @to.get_table_path
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

        puts sql
      end

      remove.each do |column|
        puts @to.get_drop_column(column)
      end
    end

    def do_insert()
      # Remove Any Elements from Array 1 that are contained in Array 2.(Difference)
      ids     = $from_ids - $to_ids
      columns = @from.get_columns()
      inserts = @from.get_data(ids)

      if !inserts.nil?
        inserts.each do |insert|
          values = insert.map{ |key, value| @from.value(value, key) }

          puts @to.get_insert(columns, values)
        end
      end
    end

    def do_update()
      # Get Common Elements between Two Arrays(Intersection)
      left  = ($from_md5s - $to_md5s).map{|k,v| k }
      right = ($to_md5s   - $from_md5s).map{|k,v| k }
      diff  = left & right
      pk    = @from.get_primary_key()

      values = @from.get_data(diff)
      if values.kind_of?(Array)
        values.map do |update|
          id     = update[pk]
          update = update.map{ |key, value| "#{key} = #{@from.value(value, key)}" if key != pk }
                         .reject{ |k, v| k.nil? }
                         .join(', ')

          puts @to.get_update(update, pk, id.to_s)
        end
      end
    end

    def do_delete()
      # Remove Any Elements from Array 1 that are contained in Array 2.(Difference)
      ids     = $to_ids - $from_ids
      id      = @to.get_primary_key()
      columns = @to.get_columns()
      deletes = @to.get_data(ids)

      if !deletes.nil?
        deletes.each do |delete|
          delete.map { |key, value| @from.value(value, key) }

          puts @to.get_delete(id, delete)
        end
      end
    end
  end
end
