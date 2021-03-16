# GraphQL

To integrate Granite with GraphQL, you can use the 'column_and_field' macros.

```crystal
@[GraphQL::Object]
class Backtest < Granite::Base
  include GraphQL::ObjectType


  def self.table_name
    "\"schemaName\".\"TableName\""
  end
  
end
```
