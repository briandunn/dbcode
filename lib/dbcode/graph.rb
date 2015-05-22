require 'tsort'
module DBCode
  LoadError = Class.new RuntimeError

  class Graph
    include TSort
    attr_reader :files

    def initialize(files)
      @files = files.map {|f| { f.name => f } }.reduce :merge
    end

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

    def compile
      tsort.map(&:to_sql).join(";\n")
    end
  end
end
