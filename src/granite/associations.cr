module Granite::Associations
  macro included
    macro inherited
      macro finished
        \\{% if !@type.constant(:INCLUDERS.id) %}
          disable_granite_docs? INCLUDERS = NamedTuple.new
        \\{% end %}
      end
    end
  end

  macro __new_includer(name, includer)
    {% if @type.constant(:INCLUDERS.id) %}
      {% INCLUDERS[name.id] = includer %}
    {% else %}
      disable_granite_docs? INCLUDERS = { "{{name.id}}": {{includer}} }
    {% end %}
  end

  macro belongs_to(model, **options)
    {%
      nilable = false
      if model.is_a? TypeDeclaration
        name = model.var.id
        type = model.type
      else
        name = model.id
        type = options[:class_name] || name.camelcase
      end
      if type.is_a? Union
        nilable = type.types.any?(&.resolve?.== Nil)
        type = type.types.find(&.resolve?.!= Nil)
      end
      if nilable
        nilable_method = name
        not_nil_method = name + "!"
      else
        nilable_method = name + "?"
        not_nil_method = name
      end
      type = type.id
    %}

    {% if options[:foreign_key] && options[:foreign_key].is_a? TypeDeclaration %}
      {% foreign_key = options[:foreign_key].var.id %}
      column {{options[:foreign_key]}}
    {% else %}
      {% foreign_key = name + "_id" %}
      column {{foreign_key}} : Int64?
    {% end %}
    {% primary_key = (options[:primary_key] || "id").id %}

    @[JSON::Field(ignore: true)]
    @[YAML::Field(ignore: true)]
    @{{name}} : {{type}}?

    __new_includer(:{{name}}, ->(children : Array({{@type}})) {
      parents = {} of Int64 | Nil => {{type}}
      {{type}}.where({{primary_key}}: children.compact_map(&.{{foreign_key}})).select.each do |parent|
        parents[parent.{{primary_key}}.try &.to_i64] = parent
      end
      children.each do |child|
        child.__set_{{name}}(parents[child.{{foreign_key}}]?)
      end
    })

    def {{nilable_method}} : {{type}}?
      @{{name}} ||= {{type}}.find_by({{primary_key}}: {{foreign_key}})
    end

    def {{not_nil_method}} : {{type}}
      @{{name}} ||= {{type}}.find_by!({{primary_key}}: {{foreign_key}})
    end

    def {{name}}=(parent : {{type}}) : {{type}}
      @{{foreign_key}} = parent.{{primary_key}}
      @{{name}} = parent
    end

    def reload_{{name}} : {{type}}?
      @{{name}} = nil
      {{nilable_method}}
    end

    def __set_{{name}}(parent : {{type}}?) : {{type}}?
      @{{name}} = parent
    end
  end

  macro has_one(model, **options)
    {%
      nilable = false
      if model.is_a? TypeDeclaration
        name = model.var.id
        type = model.type
      else
        name = model.id
        type = options[:class_name] || name.camelcase
      end
      if type.is_a? Union
        nilable = type.types.any?(&.resolve?.== Nil)
        type = type.types.find(&.resolve?.!= Nil)
      end
      if nilable
        nilable_method = name
        not_nil_method = name + "!"
      else
        nilable_method = name + "?"
        not_nil_method = name
      end
      type = type.id
    %}

    {% foreign_key = (options[:foreign_key] || @type.stringify.split("::").last.underscore + "_id").id %}
    {% primary_key = (options[:primary_key] || "id").id %}

    @[JSON::Field(ignore: true)]
    @[YAML::Field(ignore: true)]
    @{{name}} : {{type}}?

    __new_includer(:{{name}}, ->(parents : Array({{@type}})) {
      children = {} of Int64 | Nil => {{type}}
      {{type}}.where({{foreign_key}}: parents.compact_map(&.{{primary_key}})).select.each do |child|
        children[child.{{foreign_key}}.try &.to_i64] = child
      end
      parents.each do |parent|
        parent.__set_{{name}}(children[parent.{{primary_key}}]?)
      end
    })

    def {{nilable_method}} : {{type}}?
      @{{name}} ||= {{type}}.find_by({{foreign_key}}: self.{{primary_key}})
    end

    def {{not_nil_method}} : {{type}}
      @{{name}} ||= {{type}}.find_by!({{foreign_key}}: self.{{primary_key}})
    end

    def {{name}}=(child : {{type}}) : {{type}}
      child.{{foreign_key}} = self.{{primary_key}}
      @{{name}} = child
    end

    def reload_{{name}} : {{type}}?
      @{{name}} = nil
      {{nilable_method}}
    end

    def __set_{{name}}(child : {{type}}?) : {{type}}?
      @{{name}} = child
    end
  end

  macro has_many(model, **options)
    {%
      if model.is_a? TypeDeclaration
        name = model.var.id
        type = model.type
      else
        name = model.id
        type = options[:class_name] || model.id.camelcase
      end
    %}
    {%
      type = type.id
      foreign_key = (options[:foreign_key] || @type.stringify.split("::").last.underscore + "_id").id
      through = options[:through] && options[:through].id.stringify
    %}

    @{{name}} : Granite::AssociationCollection(self, {{type}})?

    def {{name}} : Granite::AssociationCollection(self, {{type}})
      @{{name}} ||= Granite::AssociationCollection(self, {{type}}).new(self, "{{foreign_key}}", {{through}})
    end

    def reload_{{name}} : Granite::AssociationCollection(self, {{type}})
      @{{name}} = nil
      {{name}}
    end
  end
end
