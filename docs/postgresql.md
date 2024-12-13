# Postgresql

In Postgres field names are case-sensitive.  If this is a pure Crystal project then this does not matter as all variable and table names will be snake_case.

However, if you need to integrate your Crystal project with another, pre-existing technology (such as a NodeJS application), then you might find that column or table names are now in camelCase.

As such you can create a class method which overrides the Granite default naming convention:

```crystal
class MyModel < Granite::Base


  def self.table_name
    "\"schemaName\".\"TableName\""
  end
  
end
```
