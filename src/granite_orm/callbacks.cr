module Granite::ORM::Callbacks
  CALLBACK_NAMES = %i(before_save after_save before_create after_create before_update after_update before_destroy after_destroy)

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
    macro {{name.id}}(callback)
      \{% CALLBACKS[{{name}}] << callback.id %}
    end

    macro __run_{{name.id}}
      \{% for callback in CALLBACKS[{{name}}] %}
         \{{callback}}
      \{% end %}
    end
  {% end %}
end
