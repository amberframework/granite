# Bulk Insertions

## Import

**Note:  Imports do not trigger callbacks automatically.  See [Running Callbacks](#running-callbacks).**

Each model has an `import` class level method to import an array of models in one bulk insert statement.
   ```Crystal
   models = [
     Model.new(id: 1, name: "Fred", age: 14),
     Model.new(id: 2, name: "Joe", age: 25),
     Model.new(id: 3, name: "John", age: 30),
   ]
   
   Model.import(models)
   ```

## update_on_duplicate

The `import` method has an optional `update_on_duplicate`  + `columns` params that allows you to specify the columns (as an array of strings) that should be updated if primary constraint is violated.
   ```Crystal
   models = [
     Model.new(id: 1, name: "Fred", age: 14),
     Model.new(id: 2, name: "Joe", age: 25),
     Model.new(id: 3, name: "John", age: 30),
   ]
   
   Model.import(models)
   
   Model.find!(1).name # => Fred
   
   models = [
     Model.new(id: 1, name: "George", age: 14),
   ]
   
   Model.import(models, update_on_duplicate: true, columns: %w(name))
   
   Model.find!(1).name # => George
   ```

**NOTE:  If using PostgreSQL you must have version 9.5+ to have the on_duplicate_key_update feature.**

## ignore_on_duplicate

The `import` method has an optional `ignore_on_duplicate` param, that takes a boolean, which will skip records if the primary constraint is violated.
   ```Crystal
   models = [
     Model.new(id: 1, name: "Fred", age: 14),
     Model.new(id: 2, name: "Joe", age: 25),
     Model.new(id: 3, name: "John", age: 30),
   ]
   
   Model.import(models)
   
   Model.find!(1).name # => Fred
   
   models = [
     Model.new(id: 1, name: "George", age: 14),
   ]
   
   Model.import(models, ignore_on_duplicate: true)
   
   Model.find!(1).name # => Fred
   ```

## batch_size

The `import` method has an optional `batch_size` param, that takes an integer.  The batch_size determines the number of models to import in each INSERT statement.  This defaults to the size of the models array, i.e. only 1 INSERT statement.
   ```Crystal
   models = [
     Model.new(id: 1, name: "Fred", age: 14),
     Model.new(id: 2, name: "Joe", age: 25),
     Model.new(id: 3, name: "John", age: 30),
     Model.new(id: 3, name: "Bill", age: 66),
   ]
   
   Model.import(models, batch_size: 2)
   # => First SQL INSERT statement imports Fred and Joe
   # => Second SQL INSERT statement imports John and Bill
   ```

## Running Callbacks

Since the `import` method runs on the class level, callbacks are not triggered automatically, they have to be triggered manually.  For example, using the Item class with a UUID primary key:
   ```Crystal
   require "uuid"
   
   class Item < Granite::Base
     adapter mysql
     table_name items
   
     primary item_id : String, auto: false
     field item_name : String
   
     before_create :generate_uuid
   
     def generate_uuid
       @item_id = UUID.random.to_s
     end
   end  
   ```

   ```Crystal
   items = [
     Item.new(item_name: "item1"),
     Item.new(item_name: "item2"),
     Item.new(item_name: "item3"),
     Item.new(item_name: "item4"),
   ]
   
   # If we did `Item.import(items)` now, it would fail since the item_id wouldn't get set before saving the record, violating the primary key constraint.
   
   # Manually run the callback on each model to generate the item_id.
   items.each(&.before_create)
   
   # Each model in the array now has a item_id set, so can be imported.
   Item.import(items)
   
   # This can also be used for a single record.
   item = Item.new(item_name: "item5")
   item.before_create
   item.save
   ```

**Note:  Manually running your callbacks is mainly aimed at bulk imports.  Running them before a normal `.save`, for example, would run your callbacks twice.**
