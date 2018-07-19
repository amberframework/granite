# JSON Support

Granite has native support for serializing and deserializing to and from JSON strings via the [JSON::Serializable](https://crystal-lang.org/api/0.25.1/JSON/Serializable.html) module.

## JSON::Field

Allows for control over the serialization and deserialization of instance variables.  

   ```Crystal
class Foo < Granite::Base
    adapter mysql
    table_name foos

    field name : String
    field password : String, json_options: {ignore: true} # skip this field in serialization and deserialization
    field age : Int32, json_options: {key: "HowOldTheyAre"} # the value of the key in the json object 
    field todayBirthday : Bool, json_options: {emit_null: true} # emits a null value for nilable property
    field isNil : Bool
end
   ```

`foo = Foo.from_json(%({"name": "Granite1", "HowOldTheyAre": 12, "password": "12345"}))`

   ```Crystal
#<Foo:0x1e5df00
    @_current_callback=nil,
    @age=12,
    @created_at=nil,
    @destroyed=false,
    @errors=[],
    @id=nil,
    @isNil=nil,
    @name="Granite1",
    @new_record=true,
    @password=nil,
    @todayBirthday=nil,
    @updated_at=nil>
   ```

`foo.to_json`

   ```JSON
{
    "name":"Granite1",
    "HowOldTheyAre":12,
    "todayBirthday":null
}
   ```

Notice how `isNil` is omitted from the JSON output since it is Nil.  If you wish to always show Nil instance variables on a class level you can do:

   ```Crystal
@[JSON::Serializable::Options(emit_nulls: true)]
class Foo < Granite::Base
    adapter mysql
    table_name foos

    field name : String
    field age : Int32
end
   ```

This would be functionally the same as adding `json_options: {emit_null: true}` on each property.

## after_initialize

This method gets called after `from_json` is done parsing the given JSON string. This allows you to set other fields that are not in the JSON directly or that require some more logic.

   ```Crystal
class Foo < Granite::Base
    adapter mysql
    table_name foos

    field name : String
    field age : Int32
    field date_added : Time

    def after_initialize
    	@date_added = Time.utc_now
    end
end
   ```

`foo = Foo.from_json(%({"name": "Granite1"}))`

   ```Crystal
<Foo:0x55c77d901ea0
    @_current_callback=nil,
    @age=0,
    @created_at=nil,
    @destroyed=false,
    @date_added=2018-07-17 01:08:28.239807000 UTC,
    @errors=[],
    @id=nil,
    @name="Granite",
    @new_record=true,
    @updated_at=nil>
   ```

## JSON::Serializable::Unmapped

If the `JSON::Serializable::Unmapped` module is included, unknown properties in the JSON document will be stored in a Hash(String, JSON::Any). On serialization, any keys inside `json_unmapped` will be serialized appended to the current JSON object.

   ```Crystal
class Foo < Granite::Base
    include JSON::Serializable::Unmapped

    adapter mysql
    table_name foos

    field name : String
    field age : Int32
end
   ```

`foo = Foo.from_json(%({"name": "Granite1", "age": 12, "foobar": true}))`

   ```Crystal
<Foo:0x55efba40ff00
    @_current_callback=nil,
    @age=12,
    @created_at=nil,
    @destroyed=false,
    @errors=[],
    @id=nil,
    @json_unmapped={"foobar" => true},
    @name="Granite1",
    @new_record=true,
    @updated_at=nil>
   ```

`foo.to_json`

   ```JSON
{
    "name": "Granite",
    "age": 12,
    "foobar": true
}
   ```