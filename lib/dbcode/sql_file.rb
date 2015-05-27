module DBCode
  class SQLFile
    attr_reader :name, :contents

    def initialize(name:, contents:)
      @name, @contents = name, contents
    end

    def dependency_names
      to_sql.scan(/^\s*-- require (\S+)\s*$/).flatten
    end

    def to_sql
      @contents
    end
  end
end
