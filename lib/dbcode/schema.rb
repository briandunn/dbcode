module DBCode
  class Schema
    attr_reader :name, :connection
    def initialize(name:, connection:)
      @name, @connection = name, connection
    end

    delegate :execute, to: :connection

    def reset!
      execute <<-SQL
        drop schema if exists #@name cascade;
        create schema #@name;
      SQL
    end

    def digest=(digest)
      execute <<-SQL
        comment on schema #@name is 'dbcode_md5:#{digest}'
      SQL
    end

    def digest
      comment = connection.select_one <<-SQL
        select pg_catalog.obj_description(n.oid, 'pg_namespace') as md5
        from pg_catalog.pg_namespace n where n.nspname = '#@name'
      SQL
      comment && comment['md5'] =~ /^dbcode_md5:(.+)$/ && $1
    end

    def within_schema(&block)
      old_path = connection.schema_search_path
      connection.schema_search_path = name
      connection.transaction(&block)
      connection.schema_search_path = old_path
    end

    def append_path!(config)
      #update all future connections
      config.merge! schema_search_path: append_schema_to_path(connection.schema_search_path)
      #update all active connections
      connection.pool.connections.each do |connection|
        connection.schema_search_path = config[:schema_search_path]
      end
    end

    private

    def append_schema_to_path(path)
      if path.split(',').include?(name)
        path
      else
        [path,name].reject(&:blank?).join ','
      end
    end
  end
end
