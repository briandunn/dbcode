require 'logger'
require 'active_record'

module DBCode
  autoload :SQLFile, 'dbcode/sql_file'
  autoload :Schema, 'dbcode/schema'
  autoload :Graph, 'dbcode/graph'
  include ActiveRecord

  extend self

  def code_schema_name
    @code_schema_name || 'code'
  end

  attr_writer :code_schema_name

  def sql_file_path
    @sql_file_path or raise "Configure sql file path. eg: #{self}.#{__method__} = Rails.root"
  end

  attr_writer :sql_file_path

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  attr_writer :logger

  def env
    @env ||= 'development'
  end

  attr_writer :env

  def prepare
    code = Schema.new connection: Base.connection, name: code_schema_name
    code.append_path!(Base.connection_config)

    begin
      Migration.check_pending!
    rescue PendingMigrationError
      return
    end

    code.within_schema do
      graph = build_graph

      if code.digest != graph.digest
        if env == 'production'
          return logger.error "[dbcode] out of date, but refusing to reset #{code.name} in production."
        end
        logger.warn "[dbcode] Resetting schema #{code.name}"
        code.reset!
        code.execute graph.to_sql
        code.digest = graph.digest
      else
        logger.info "[dbcode] Schema #{code.name} is up to date"
      end
    end
  end

  def build_graph
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
