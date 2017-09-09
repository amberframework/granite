module Granite::ORM::Callbacks
  CALLBACK_NAMES = %i(before_save after_save before_create after_create before_update after_update before_destroy after_destroy)

  macro included
    macro inherited
      CALLBACKS = {} of Nil => Nil
    end
  end

  {% for name in CALLBACK_NAMES %}
    macro {{name.id}}(callback)
      \{% CALLBACKS[{{name}}] = callback.id %}
    end

    macro __run_{{name.id}}
      \{{CALLBACKS[{{name}}]}}
    end
  {% end %}
end
