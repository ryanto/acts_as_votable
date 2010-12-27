$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require 'acts_as_votable'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

ActiveRecord::Schema.define(:version => 1) do
  create_table :votes do |t|
    t.references :votable, :polymorphic => true
    t.references :voter, :polymorphic => true

    t.boolean :vote_flag

    t.timestamps
  end

  add_index :votes, [:votable_id, :votable_type]
  add_index :votes, [:voter_id, :voter_type]

  create_table :voters do |t|
    t.string :name
  end

  create_table :votable_models do |t|
    t.string :name
  end

  create_table :not_votable_models do |t|
    t.string :name
  end

end


class Voter < ActiveRecord::Base
  
end

class VotableModel < ActiveRecord::Base
  acts_as_votable
  validates_presence_of :name
end

class NotVotableModel < ActiveRecord::Base
end



def clean_database
  models = [ActsAsVotable::Vote, Voter, VotableModel, NotVotableModel]
  models.each do |model|
    ActiveRecord::Base.connection.execute "DELETE FROM #{model.table_name}"
  end
end