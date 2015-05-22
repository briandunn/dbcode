require 'tsort'
module DBCode
  LoadError = Class.new RuntimeError

  class Graph
    include TSort
    attr_reader :files

    def initialize(files)
      @files = files
    end

    def tsort_each_child(file, &block)
      file.dependency_names.each do |name|
        if dependency = files.find {|f| f.name == name }
          block.call(dependency)
        else
          raise LoadError, %Q{cannot load file -- #{name}}
        end
      end
    end

    def tsort_each_node(&b)
      files.each(&b)
    end

    def compile
      tsort.map(&:to_sql).join(";\n")
    end
  end
end
