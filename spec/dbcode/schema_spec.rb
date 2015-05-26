require 'active_support'
require 'active_support/core_ext'
require 'dbcode/schema'

describe DBCode::Schema do
  let(:schema) { described_class.new(name: 'pants', connection: connection) }
  let(:connection) do
    double 'Connection', schema_search_path: 'public', :schema_search_path= => 'foo'
  end

  describe '#within_schema' do
    it 'ensures everything in the block is in this schema' do
      allow(connection).to receive(:transaction).and_yield
      schema.within_schema do
        expect(connection).to have_received(:schema_search_path=).once.with 'pants'
      end
      expect(connection).to have_received(:schema_search_path=).once.with 'public'
      expect(connection).to have_received(:schema_search_path=).twice
    end
  end

  describe '#digest' do
    subject { schema.digest }

    context 'when there is no digest comment' do
      before do
        allow(connection).to receive(:select_one).and_return nil
      end

      it { should be_nil }
    end
    context 'when there is a digest comment' do
      before do
        allow(connection).to receive(:select_one).and_return 'md5' => 'dbcode_md5:abc'
      end

      it { should eq 'abc' }
    end

    context 'when there is a different comment' do
      before do
        allow(connection).to receive(:select_one).and_return 'md5' => 'my favorite schema!'
      end

      it { should be_nil }
    end
  end
end
