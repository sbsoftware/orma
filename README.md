# Orma

Orma is an ActiveRecord-style persistence layer for Crystal with built-in continuous migration. It aims to keep record definitions, querying, associations, and schema evolution close together so you can move quickly without maintaining a separate migration workflow for every change.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     orma:
       github: sbsoftware/orma
   ```

2. Run `shards install`

## Usage

```crystal
require "orma"

# ENV["DATABASE_URL"] must be set

class Post < Orma::Record
  column title : String

  has_many_of Comment
end

class Comment < Orma::Record
  column body : String

  belongs_to Post
end

post = Post.create(title: "Hello")
Comment.create(body: "Nice post", post_id: post.id)

comments = Comment.where(post_id: post.id)
comment = comments.first
comment.post.title # => "Hello"
```

## Why Orma

- Define records with columns directly in Crystal
- Query records with a compact, chainable API
- Model relationships with `belongs_to` and `has_many`
- Keep schema changes in sync through continuous migration
- Work against supported database backends without centering the API around one specific adapter

## Core Concepts

### Records and columns

Define your model as a Crystal class inheriting from `Orma::Record`. Columns are declared in the class body, and Orma uses those declarations as the source of truth for persistence and schema management.

### Query chaining

Records can be queried through a chainable API for filtering, ordering, and limiting result sets, giving you an ActiveRecord-like workflow while staying close to Crystal types.

### Associations

Orma supports common record relationships such as `belongs_to` and `has_many`, so related records can be modeled directly in your domain classes.

### Continuous migration

Continuous migration is an experimental, yet central feature of Orma.

Instead of maintaining a separate migration file for each schema change, Orma can derive and apply structural changes from your record definitions.

Column removal is designed as a staged process. If you want to retire a column, change it from `column` to `deprecated_column`. Continuous migration will rename the backing column to `_<name>_deprecated` while keeping the value readable through the model.

After the deprecated column is no longer needed, remove the `deprecated_column` declaration from the model. On the next migration run, Orma will delete the matching `_<name>_deprecated` column. Note that simply removing non-deprecated column definitions will leave them in the database as-is.

This is currently the built-in path for schema evolution and should be treated with appropriate care, especially in production environments.
To enable it, set `ENV["ORMA_CONTINUOUS_MIGRATION"]=1`. Opting out of it means you'll have to take care of migrations yourself.

## Supported Databases

Orma currently supports:

- SQLite3
- PostgreSQL

## Development

Run the test suite:

```bash
crystal spec
```

## Contributing

1. Fork it (<https://github.com/sbsoftware/orma/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Stefan Bilharz](https://github.com/sbsoftware) - creator and maintainer
