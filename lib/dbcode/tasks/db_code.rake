namespace :db do
  namespace :code do
    desc "sync the database code schema with the declaration files"
    task sync: :environment do
      DBCode.prepare
    end
  end

  task :migrate do
    DBCode.prepare
  end
end
