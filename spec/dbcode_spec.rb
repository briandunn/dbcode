require 'active_record'
require 'dbcode'

describe 'dbcode' do
  def database_name; 'dbcode_test' end
  before(:all) do
    system "dropdb #{database_name}; createdb #{database_name}"
  end

  around do |test|
    ActiveRecord::Base.establish_connection(
      adapter: 'postgresql', database: database_name
    )
    ActiveRecord::Base.connection.transaction do
      test.call
      raise ActiveRecord::Rollback
    end
    ActiveRecord::Base.clear_all_connections!
  end

  let(:sql_file_path) do
    Pathname(__FILE__).join('../test_app/db/code').tap(&:mkpath)
  end

  before do
    sql_file_path.rmtree
    DBCode.sql_file_path = sql_file_path
  end

  def create_view_file name, contents
    sql_file_path.join('views').tap(&:mkpath).join("#{name}.sql").write contents
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

  specify 'concatenates files with sprockets require statements' do
    create_view_file 'foo', <<-SQL
    create view foo as select 1 as number
    SQL

    create_view_file 'bar', <<-SQL
    -- require foo
    create view bar as select * from foo
    SQL

    expect { DBCode.ensure_freshness! }.to_not raise_error
  end

  it 'only executes when the code is updated' do
    create_view_file 'foo', <<-SQL
      create view foo as select 1 as number
    SQL

    DBCode.ensure_freshness!

    expect {
      DBCode.ensure_freshness!
    }.to_not change {
      connection.select_one(<<-SQL).fetch('oid')
        select oid from pg_catalog.pg_namespace where nspname = 'code';
      SQL
    }
  end

  specify "subsequent ddl statements work go into public schema" do
    expect(connection.schema_search_path.split(',')).to_not include 'code'
    DBCode.ensure_freshness!
    connection.execute <<-SQL
    create table foos (id serial)
    SQL
    expect(connection.select_one(<<-SQL).fetch('nspname')).to eq 'public'
      select nspname
      from pg_class
      join pg_namespace on relnamespace = pg_namespace.oid
      where relname = 'foos'
    SQL
  end
end
