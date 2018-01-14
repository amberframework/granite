require "spec"

module GraniteExample
  ADAPTERS = ["pg","mysql","sqlite"]
  @@model_classes = [] of Granite::ORM::Base.class

  extend self

  def model_classes
    @@model_classes
  end
end

require "../src/granite_orm"
require "./spec_models"

Granite::ORM.settings.logger = ::Logger.new(nil)

GraniteExample.model_classes.each do |model|
  model.drop_and_create
end
