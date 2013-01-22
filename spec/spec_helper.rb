$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require 'acts_as_votable'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

ActiveRecord::Schema.define(:version => 1) do
  create_table :votes do |t|
    t.references :votable, :polymorphic => true
    t.references :voter, :polymorphic => true

    t.boolean :vote_flag
    t.string :vote_scope

    t.timestamps
  end

  add_index :votes, [:votable_id, :votable_type]
  add_index :votes, [:voter_id, :voter_type]
  add_index :votes, [:voter_id, :voter_type, :vote_scope]
  add_index :votes, [:votable_id, :votable_type, :vote_scope]

  create_table :voters do |t|
    t.string :name
  end

  create_table :not_voters do |t|
    t.string :name
  end

  create_table :votables do |t|
    t.string :name
  end

  create_table :sti_votables do |t|
    t.string :name
    t.string :type
  end

  create_table :sti_not_votables do |t|
    t.string :name
    t.string :type
  end

  create_table :not_votables do |t|
    t.string :name
  end

  create_table :votable_caches do |t|
    t.string :name
    t.integer :cached_votes_total
    t.integer :cached_votes_score
    t.integer :cached_votes_up
    t.integer :cached_votes_down
  end

end


class Voter < ActiveRecord::Base
  acts_as_voter
end

class NotVoter < ActiveRecord::Base
  
end

class Votable < ActiveRecord::Base
  acts_as_votable
  validates_presence_of :name
end

class StiVotable < ActiveRecord::Base
  acts_as_votable
end

class ChildOfStiVotable < StiVotable
end

class StiNotVotable < ActiveRecord::Base
  validates_presence_of :name
end

class VotableChildOfStiNotVotable < StiNotVotable
  acts_as_votable
end

class NotVotable < ActiveRecord::Base
end

class VotableCache < ActiveRecord::Base
  acts_as_votable
  validates_presence_of :name
end

class ABoringClass
  def self.hw
    'hello world'
  end
end


def clean_database
  models = [ActsAsVotable::Vote, Voter, NotVoter, Votable, NotVotable, VotableCache]
  models.each do |model|
    ActiveRecord::Base.connection.execute "DELETE FROM #{model.table_name}"
  end
end
