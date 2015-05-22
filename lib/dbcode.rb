module DBCode
  autoload :SQLFile, 'dbcode/sql_file'
  autoload :Graph, 'dbcode/graph'
  extend self
  attr_accessor :sql_file_path

  def ensure_freshness!
    reset_search_path 'tmp'
    connection.execute graph.compile
  end

  def graph
    Graph.new file_names.sort.map &SQLFile.method(:new)
  end

  def file_names
    Dir[sql_file_path.join('**/*.sql').expand_path]
  end

  def reset_search_path(schema)
    connection.execute <<-SQL
      drop schema if exists #{schema} cascade;
      create schema #{schema};
    SQL
    #update all future connections
    ActiveRecord::Base.connection_config.merge! schema_search_path: prepend_schema_to_path(schema, connection.schema_search_path)
    #update all active connections
    connection.pool.connections.each do |connection|
      connection.schema_search_path = prepend_schema_to_path schema, connection.schema_search_path
    end
  end

  def connection
    ActiveRecord::Base.connection
  end

  def prepend_schema_to_path(schema,path)
    if path.split(',').include?(schema)
      path
    else
      [schema,path].reject(&:blank?).join ','
    end
  end
end

require 'dbcode/railtie' if defined? Rails
