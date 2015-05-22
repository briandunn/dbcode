module DBCode
  class Railtie < Rails::Railtie
    initializer "dbcode.setup" do |app|
      DBCode.sql_file_path = app.root.join 'db/code'
      config.watchable_dirs[DBCode.sql_file_path.to_s] = ['sql']
    end

    config.to_prepare &DBCode.method(:ensure_freshness!)
  end
end
