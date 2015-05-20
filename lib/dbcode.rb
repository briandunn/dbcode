module DBCode
  extend self
  def ensure_freshness!
    reset_search_path 'tmp'
    files = Dir[Rails.root.join('db/code/**/*.sql').expand_path]
    for file in files.sort
      execute File.read file
    end
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
