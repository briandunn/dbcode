require 'active_record'
require 'dbcode'

module Rails
  def self.root
    Pathname(__FILE__).join('../../test_app')
  end
end

describe 'dbcode' do
  around do |test|
    ActiveRecord::Base.establish_connection(
      adapter: 'postgresql', database: 'dbcode_test'
    )
    ActiveRecord::Base.connection.transaction do
      test.call
      raise ActiveRecord::Rollback
    end
  end

  before do
    Rails.root.join('db/code').rmtree
  end

  def create_view_file name, contents
    Rails.root.join('db/code/views').tap(&:mkpath).join("#{name}.sql").write contents
  end

  def connection
    ActiveRecord::Base.connection
  end

  specify 'new connections use new declarations of a view' do
    create_view_file 'foo', <<-SQL
      create view foo as select 1 as number
    SQL
    DBCode.ensure_freshness!

    expect(connection.select_one('select number from foo')).to eq 'number' => '1'
    create_view_file 'foo', <<-SQL
      create view foo as select 2 as number
    SQL
    DBCode.ensure_freshness!
    expect(connection.select_one('select number from foo')).to eq 'number' => '2'
  end

end
