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
    search_path = execute("show search_path").first.fetch 'search_path'
    execute <<-SQL
      drop schema if exists #{schema} cascade;
      create schema if not exists #{schema};
    SQL
    unless search_path.split(',').first == schema
      execute "set search_path to #{schema},#{search_path}"
    end
  end

  def execute(sql)
    ActiveRecord::Base.connection.execute sql
  end
end
