require 'active_support'
require 'active_support/core_ext'
require 'dbcode/schema'

describe DBCode::Schema do
  describe '#within_schema' do
    let(:connection) do
      double 'Connection', schema_search_path: 'public', :schema_search_path= => 'foo'
    end

    it 'ensures everything in the block is in this schema' do
      schema = described_class.new(name: 'pants', connection: connection)
      schema.within_schema do
        expect(connection).to have_received(:schema_search_path=).once.with 'pants'
      end
      expect(connection).to have_received(:schema_search_path=).once.with 'public'
      expect(connection).to have_received(:schema_search_path=).twice
    end
  end
end
