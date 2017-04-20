require "./spec_helper"
require "../src/adapter/pg"

class Todo < Kemalyst::Model
  adapter pg
  field name : String
  timestamps

  def initialize(@name)
  end
end

describe Kemalyst::Model do
end
