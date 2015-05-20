module DBCode
  extend self
  def ensure_freshness!
    reset_search_path 'tmp'
    file_names = Dir[Rails.root.join('db/code/**/*.sql').expand_path]
    execute Graph.new(file_names.sort.map(&SQLFile.method(:new))).compile
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

class Graph
  include TSort
  attr_reader :files

  def initialize(files)
    @files = files
  end

  def tsort_each_child(file, &b)
    file.dependencies.each(&b)
  end

  def tsort_each_node(&b)
    files.each(&b)
  end

  def compile
    tsort.reverse.map(&:to_sql).join(";\n")
  end
end

class SQLFile
  attr_reader :path

  def initialize(path)
    @path = Pathname(path)
  end

  def name
    path.basename('.sql')
  end

  def dependencies
    to_sql.scan(/^-- require (\S+)/).flatten
  end

  def to_sql
    @sql ||= path.read
  end
end
