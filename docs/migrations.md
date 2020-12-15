# Migrations

## Database Migrations with micrate

If you're using Granite to query your data, you likely want to manage your database schema as well. Migrations are a great way to do that, so let's take a look at [micrate](https://github.com/juanedi/micrate), a project to manage migrations. We'll use it as a dependency instead of a pre-build binary.

### Install

Add micrate your shards.yml

```yaml
dependencies:
  micrate:
    github: juanedi/micrate
```

Update shards
```sh
$ shards update
```

Create an executable to run the `Micrate::Cli`. For this example, we'll create `bin/micrate` in the root of our project where we're using Granite ORM. This assumes you're exporting the `DATABASE_URL` for your project and an environment variable instead of using a `database.yml`.

```crystal
#! /usr/bin/env crystal
#
# To build a standalone command line client, require the
# driver you wish to use and use `Micrate::Cli`.
#

require "micrate"
require "pg"

Micrate::DB.connection_url = ENV["DATABASE_URL"]
Micrate::Cli.run
```

Make it executable:
```sh
$ chmod +x bin/micrate
```

We should now be able to run micrate commands.

`$ bin/micrate help` => should output help commands.

### Creating a migration

Let's create a `posts` table in our database.

```sh
$ bin/micrate create create_posts
```

This will create a file under `db/migrations`. Let's open it and define our posts schema.

```sql
-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied
CREATE TABLE posts(
  id BIGSERIAL PRIMARY KEY,
  title VARCHAR NOT NULL,
  body TEXT NOT NULL,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back
DROP TABLE posts;
```

And now let's run the migration
```sh
$ bin/micrate up
```

You should now have a `posts` table in your database ready to query.
