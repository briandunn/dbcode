require 'dbcode/graph'
require 'dbcode/sql_file'

describe DBCode::Graph do
  def file_double(methods)
    double DBCode::SQLFile, methods
  end

  it 'sorts two interdependent files' do
    file_1 = file_double name: 'file_1', dependency_names: ['file_2'], to_sql: 'file 1'
    file_2 = file_double name: 'file_2', dependency_names: [], to_sql: 'file 2'
    expect(described_class.new([file_1,file_2]).compile).to eq "file 2;\nfile 1"
  end

  it 'resolves a triangle' do
    file_1 = file_double name: 'file_1', dependency_names: ['file_2'], to_sql: 'file 1'
    file_2 = file_double name: 'file_2', dependency_names: [], to_sql: 'file 2'
    file_3 = file_double name: 'file_3', dependency_names: ['file_2'], to_sql: 'file 3'
    expect(described_class.new([file_1,file_2,file_3]).compile).to eq "file 2;\nfile 1;\nfile 3"
  end

  it 'resolves a chain of three' do
    file_1 = file_double name: 'file_1', dependency_names: ['file_2'], to_sql: 'file 1'
    file_2 = file_double name: 'file_2', dependency_names: ['file_3'], to_sql: 'file 2'
    file_3 = file_double name: 'file_3', dependency_names: [], to_sql: 'file 3'
    expect(described_class.new([file_1,file_2,file_3]).compile).to eq "file 3;\nfile 2;\nfile 1"
  end

  it 'raises when a file is missing' do
    file_1 = file_double name: 'file_1', dependency_names: ['file_2'], to_sql: 'file 1'
    expect do
      described_class.new([file_1]).compile
    end.to raise_error DBCode::LoadError, 'cannot load file -- file_2'
  end

  it 'is empty when empty' do
    expect(described_class.new({}).to_sql).to eq ''
  end
end
