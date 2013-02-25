class ActsAsVotableMigration < ActiveRecord::Migration
  def self.up
    create_table :votes do |t|

      t.integer :votable_id
      t.integer :voter_id

      t.boolean :vote_flag
      t.string :vote_scope

      t.timestamps
    end

    add_index :votes, [:votable_id, :votable_type]
    add_index :votes, [:voter_id, :voter_type]
    add_index :votes, [:voter_id, :voter_type, :vote_scope]
    add_index :votes, [:votable_id, :votable_type, :vote_scope]
  end

  def self.down
    drop_table :votes
  end
end
