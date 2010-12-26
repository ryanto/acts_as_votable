class ActsAsVotableMigration < ActiveRecord::Migration
  def self.up
    create_table :votes do |t|

      t.references :votable, :polymorphic => true
      t.references :voter, :polymorphic => true

      t.boolean :vote_flag

      t.timestamps
    end

    add_index :votes, [:votable_id, :votable_type]
    add_index :votes, [:voter_id, :voter_type]
  end

  def self.down
    drop_table :votes
  end
end