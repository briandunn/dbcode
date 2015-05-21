module DBCode
  class Graph
    include TSort
    attr_reader :files

    def initialize(files)
      @files = files
    end

    def tsort_each_child(file, &b)
      file.dependencies.each(&b)
    end

    def tsort_each_node(&b)
      files.each(&b)
    end

    def compile
      tsort.reverse.map(&:to_sql).join(";\n")
    end
  end
end
