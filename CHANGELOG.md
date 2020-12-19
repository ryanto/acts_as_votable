# Change log

## master (unreleased)

### Bug Fixes

* [#127](https://github.com/ryanto/acts_as_votable/issues/127): Fix races that lead to duplicate votes creation. ([@fatkodima][])

  For this to work, you need to update your database schema and existing data.
  ```ruby
  # 1. Add a new column to the `votes` table.
  add_column :votes, :uniqueness_token, :string

  # 2. Manually remove erroneously created duplicate votes.

  # 3. If you are using `duplicate: true` while voting in your codebase,
  # update all those duplicated votes by setting a unique `uniqueness_token` for each of them,
  # something like a unique hex value would suffice.

  # 4. For other non duplicated votes update all of them setting the
  # `uniqueness_token` field to "unique vote" string value.

  # 5. Update `uniqueness_token` column to disallow NULL values.
  change_column_null :votes, :uniqueness_token, false

  # 6. Add a new unique index
  add_index :votes, [:voter_id, :voter_type, :vote_scope, :votable_id, :votable_type, :uniqueness_token],
    name: "index_votes_uniqueness", unique: true

  # 7. Now you can delete the old index
  remove_index :votes, [:voter_id, :voter_type, :vote_scope]
  ```

  NOTE: Make sure you adapted that steps for your workload and run that commands safely
  (adding/removing indexes concurrently, updating columns in batches, etc).

[@fatkodima]: https://github.com/fatkodima
