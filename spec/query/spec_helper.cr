require "spec"
require "db"
require "../../../../src/ext/query_builder"

class Model
  def self.table_name
    "table"
  end

  def self.fields
    ["name", "age"]
  end

  def self.primary_name
    "id"
  end
end

def query_fields
  [Model.primary_name, Model.fields].flatten.join ", "
end

def builder
  builder = Query::Builder(Model).new
end

def assembler
  Query::Assembler::Postgresql(Model).new builder
end
