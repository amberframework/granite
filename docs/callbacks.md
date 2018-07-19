# Callbacks

Call a specified method on a specific life cycle event.

Here is an example:

```crystal
require "granite/adapter/pg"

class Post < Granite::Base
  adapter pg

  before_save :upcase_title

  field title : String
  field content : String
  timestamps

  def upcase_title
    if title = @title
      @title = title.upcase
    end
  end
end
```

You can register callbacks for the following events:

## Create

- before_save
- before_create
- **save**
- after_create
- after_save

## Update

- before_save
- before_update
- **save**
- after_update
- after_save

## Destroy

- before_destroy
- **destroy**
- after_destroy
