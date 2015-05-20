module DBCode
  extend self
  def ensure_freshness!
    files = Dir[Rails.root.join('db/code/**/*.sql').expand_path]
    files.each do |file|
      ActiveRecord::Base.connection.execute File.read file
    end
  end
end
