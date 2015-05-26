module DBCode
  autoload :SQLFile, 'dbcode/sql_file'
  autoload :Schema, 'dbcode/schema'
  autoload :Graph, 'dbcode/graph'
  extend self
  attr_accessor :sql_file_path

  def ensure_freshness!
    code = Schema.new connection: ActiveRecord::Base.connection, name: 'code'
    code.within_schema do
      unless code.digest == graph.digest
        code.reset!
        code.execute graph.to_sql
        code.digest = graph.digest
      end
    end
    code.append_path!(ActiveRecord::Base.connection_config)
  end

  def graph
    Graph.new file_names.sort.map &SQLFile.method(:new)
  end

  def file_names
    Dir[sql_file_path.join('**/*.sql').expand_path]
  end
end

require 'dbcode/railtie' if defined? Rails
