module Granite::Callbacks
  class Abort < Exception
  end

  CALLBACK_NAMES = %w(before_save after_save before_create after_create before_update after_update before_destroy after_destroy)

  @[JSON::Field(ignore: true)]
  @[YAML::Field(ignore: true)]
  @_current_callback : String?

  macro included
    macro inherited
      disable_granite_docs? CALLBACKS = {
        {% for name in CALLBACK_NAMES %}
          {{name.id}}: [] of Nil,
        {% end %}
      }
      {% for name in CALLBACK_NAMES %}
        disable_granite_docs? def {{name.id}}
          __{{name.id}}
        end
      {% end %}
    end
  end

  {% for name in CALLBACK_NAMES %}
    macro {{name.id}}(*callbacks, &block)
      \{% for callback in callbacks %}
        \{% CALLBACKS[{{name}}] << callback %}
      \{% end %}
      \{% if block.is_a? Block %}
        \{% CALLBACKS[{{name}}] << block %}
      \{% end %}
    end

    macro __{{name.id}}
      @_current_callback = {{name}}
      \{% for callback in CALLBACKS[{{name}}] %}
        \{% if callback.is_a? Block %}
           begin
             \{{callback.body}}
           end
        \{% else %}
          \{{callback.id}}
        \{% end %}
      \{% end %}
    end
  {% end %}

  def abort!(message = "Aborted at #{@_current_callback}.")
    raise Abort.new(message)
  end
end
