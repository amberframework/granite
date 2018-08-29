# Errors

All database errors are added to the `errors` array used by Granite::Validators with the symbol ':base'

```crystal
post = Post.new
post.save
post.errors[0].to_s.should eq "ERROR: name cannot be null"
```
## Validations

Validations can be made on models to ensure that given criteria are met.

Models that do not pass the validations will not be saved, and will have the errors added to the model's `errors` array.

For example, asserting that the title on a post is not blank:

```Crystal
class Post < Granite::Base
  adapter mysql

  field title : String

  validate :title, "can't be blank" do |post|
    !post.title.to_s.blank?
  end
end
`
```

## Validation Helpers

A set of common validation macros exist to make validations easier to manage/create.

### Common

- `validate_not_nil :field` - Validates that field should not be nil.
- `validate_is_nil :field` - Validates that field should be nil.
- `validate_is_valid_choice :type, ["allowedType1", "allowedType2"]` - Validates that type should be one of a preset option.
- `validate_uniqueness :field` - Validates that the field is unique

### String

- `validate_not_blank :field` - Validates that field should not be blank.
- `validate_is_blank :field` - Validates that field should be blank.
- `validate_min_length :field, 5` - Validates that field should be at least 5 long
- `validate_max_length :field, 20` - Validates that field should be at most 20 long

### String

- `validate_greater_than :field, 0` - Validates that field should be greater than 0.
- `validate_greater_than :field, 0, true` - Validates that field should be greater than or equal to 0.
- `validate_less_than :field, 100` - Validates that field should be less than 100.
- `validate_less_than :field, 100, true` - Validates that field should be less than or equal to 100.

Using the helpers, the previous example could have been written like:

```Crystal
class Post < Granite::Base
  adapter mysql

  field title : String

  validate_not_blank :title
end
```