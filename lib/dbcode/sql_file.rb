module DBCode
  class SQLFile
    attr_reader :path

    def initialize(path)
      @path = Pathname(path)
    end

    def name
      path.basename('.sql')
    end

    def dependencies
      to_sql.scan(/^-- require (\S+)/).flatten
    end

    def to_sql
      @sql ||= path.read
    end
  end
end
