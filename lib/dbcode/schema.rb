module DBCode
  class SearchPath
    def initialize(path)
      @path = path.to_s.split ','
    end

    def prepend(schema)
      from_parts [schema] + path
    end

    def append(schema)
      from_parts path + [schema]
    end

    def to_s
      path.join ','
    end

    def include?(name)
      path.include? name
    end

    private
    attr_reader :path

    def from_parts(parts)
      self.class.new parts.join ','
    end
  end

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
      old_path = search_path
      connection.schema_search_path = old_path.prepend(name).to_s
      connection.transaction(&block)
      connection.schema_search_path = old_path.to_s
    end

    def append_path!(config)
      return if search_path.include? name

      #update all future connections
      config.merge! schema_search_path: search_path.append(name).to_s
      #update all active connections
      connection.pool.connections.each do |connection|
        connection.schema_search_path = config[:schema_search_path]
      end
    end

    private
    def search_path
      SearchPath.new(connection.schema_search_path)
    end
  end
end
