require 'active_record'
require 'dbcode'

module Rails
  def self.root
    Pathname(__FILE__).join('../../test_app')
  end
end

describe 'dbcode' do
  before do
    ActiveRecord::Base.establish_connection(
      adapter: 'postgresql', database: 'dbcode_test'
    )
  end

  def create_view_file name, contents
    Rails.root.join('db/code/views').tap(&:mkpath).join('foo.sql').write contents
  end

  def connection
    ActiveRecord::Base.connection
  end

  specify 'new connections use new declarations of a view' do

    create_view_file 'foo', <<-SQL
      drop view if exists foo;
      create view foo as select 1 as number
    SQL
    DBCode.ensure_freshness!

    expect(connection.select_one('select number from foo')).to eq 'number' => '1'
    create_view_file 'foo', <<-SQL
      drop view if exists foo;
      create view foo as select 2 as number
    SQL
    DBCode.ensure_freshness!
    expect(connection.select_one('select number from foo')).to eq 'number' => '2'
  end
end
