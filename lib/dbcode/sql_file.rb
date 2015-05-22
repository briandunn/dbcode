module DBCode
  class SQLFile
    attr_reader :path

    def initialize(path)
      @path = Pathname(path)
    end

    def name
      path.basename('.sql').to_s
    end

    def dependency_names
      to_sql.scan(/^\s*-- require (\S+)\s*$/).flatten
    end

    def to_sql
      @sql ||= path.read
    end
  end
end
