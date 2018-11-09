# frozen_string_literal: true

ActiveRecord::Schema.define(version: 1) do
  create_table :votes, force: true do |t|
    t.references :votable, polymorphic: true
    t.references :voter, polymorphic: true

    t.boolean :vote_flag
    t.string :vote_scope
    t.integer :vote_weight

    t.timestamps(null: false, precision: 6)
  end

  add_index :votes, [:votable_id, :votable_type]
  add_index :votes, [:voter_id, :voter_type]
  add_index :votes, [:voter_id, :voter_type, :vote_scope]
  add_index :votes, [:votable_id, :votable_type, :vote_scope]

  create_table :voters, force: true do |t|
    t.string :name
  end

  create_table :not_voters, force: true do |t|
    t.string :name
  end

  create_table :votables, force: true do |t|
    t.string :name
  end

  create_table :votable_voters, force: true do |t|
    t.string :name
  end

  create_table :sti_votables, force: true do |t|
    t.string :name
    t.string :type
  end

  create_table :sti_not_votables, force: true do |t|
    t.string :name
    t.string :type
  end

  create_table :not_votables, force: true do |t|
    t.string :name
  end

  create_table :votable_caches, force: true do |t|
    t.string :name
    t.integer :cached_votes_total
    t.integer :cached_votes_score
    t.integer :cached_votes_up
    t.integer :cached_votes_down
    t.integer :cached_weighted_total
    t.integer :cached_weighted_score
    t.float :cached_weighted_average

    t.integer :cached_scoped_test_votes_total
    t.integer :cached_scoped_test_votes_score
    t.integer :cached_scoped_test_votes_up
    t.integer :cached_scoped_test_votes_down
    t.integer :cached_scoped_weighted_total
    t.integer :cached_scoped_weighted_score
    t.float :cached_scoped_weighted_average

    t.timestamps(null: false, precision: 6)
  end
end
