module Granite::ORM::Callbacks
  class Abort < Exception
  end

  CALLBACK_NAMES = %i(before_save after_save before_create after_create before_update after_update before_destroy after_destroy)

  @_current_callback : Symbol?

  macro included
    macro inherited
      CALLBACKS = {
        {% for name in CALLBACK_NAMES %}
          {{name.id}}: [] of Nil,
        {% end %}
      }
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

    macro __run_{{name.id}}
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
