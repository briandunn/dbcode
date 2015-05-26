require 'tsort'
module DBCode
  LoadError = Class.new RuntimeError

  class Graph
    include TSort

    def initialize(files)
      @files = files.map {|f| { f.name => f } }.reduce(:merge).freeze
    end

    def digest
      Digest::MD5.base64digest to_sql
    end

    def compile
      tsort.map(&:to_sql).join(";\n")
    end

    def to_sql
      @to_sql ||= compile
    end

    private

    attr_reader :files

    def tsort_each_child(file, &block)
      file.dependency_names.each do |name|
        dependency = files.fetch name do
          raise LoadError, %Q{cannot load file -- #{name}}
        end

        block.call dependency
      end
    end

    def tsort_each_node(&b)
      files.values.each(&b)
    end
  end
end
