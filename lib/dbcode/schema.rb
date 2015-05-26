module DBCode
  class Schema
    attr_reader :name, :connection
    def initialize(name:, connection:)
      @name, @connection = name, connection
    end

    delegate :execute, to: :connection

    def reset!
      connection.execute <<-SQL
        drop schema if exists #@name cascade;
        create schema #@name;
      SQL
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
