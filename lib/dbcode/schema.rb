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
      comment = execute(<<-SQL).first
        select pg_catalog.obj_description(n.oid, 'pg_namespace') as md5
        from pg_catalog.pg_namespace n where n.nspname = '#@name'
      SQL
      if comment
        comment.fetch('md5') && comment.fetch('md5').match(/^dbcode_md5:(?<md5>.+)$/)[:md5]
      end
    end

    def prepend_path!(config)
      #update all future connections
      config.merge! schema_search_path: prepend_schema_to_path(connection.schema_search_path)
      #update all active connections
      connection.pool.connections.each do |connection|
        connection.schema_search_path = config[:schema_search_path]
      end
    end

    private

    def prepend_schema_to_path(path)
      if path.split(',').include?(name)
        path
      else
        [name,path].reject(&:blank?).join ','
      end
    end
  end
end
