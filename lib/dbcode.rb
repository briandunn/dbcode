module DBCode
  autoload :SQLFile, 'dbcode/sql_file'
  autoload :Schema, 'dbcode/schema'
  autoload :Graph, 'dbcode/graph'
  extend self
  attr_accessor :sql_file_path, :code_schema_name
  self.code_schema_name ||= 'code'

  def ensure_freshness!
    code = Schema.new connection: ActiveRecord::Base.connection, name: code_schema_name
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
    Graph.new files.map &SQLFile.method(:new)
  end

  def files
    Dir[sql_file_path.join('**/*.sql').expand_path].sort.map do |file_name|
      path = Pathname(file_name)
      {
        name: path.relative_path_from(sql_file_path).sub(/.sql$/,'').to_s,
        contents: path.read
      }
    end
  end
end

require 'dbcode/railtie' if defined? Rails
