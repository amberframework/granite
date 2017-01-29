require "./spec_helper"
require "../src/adapter/pg"

class Todo < Kemalyst::Model
  adapter pg

  sql_mapping({
    name: String,
  })

  def initialize(@name)
  end
end

describe Kemalyst::Model do
end
