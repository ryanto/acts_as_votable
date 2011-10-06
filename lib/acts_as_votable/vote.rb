require 'acts_as_votable/helpers/words'

module ActsAsVotable
  class Vote < ::ActiveRecord::Base

    include Helpers::Words

    attr_accessible :votable_id, :votable_type,
      :voter_id, :voter_type,
      :votable, :voter,
      :vote_flag

    belongs_to :votable, :polymorphic => true
    belongs_to :voter, :polymorphic => true

    validates_presence_of :votable_id
    validates_presence_of :voter_id

  end

end

