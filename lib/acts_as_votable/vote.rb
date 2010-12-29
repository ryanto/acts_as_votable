module ActsAsVotable
  class Vote < ::ActiveRecord::Base

    attr_accessible :votable_id, :votable_type,
      :voter_id, :voter_type,
      :votable, :voter,
      :vote_flag

    belongs_to :votable, :polymorphic => true
    belongs_to :voter, :polymorphic => true

    validates_presence_of :votable_id
    validates_presence_of :voter_id

    def self.true_votes
      ['up', 'upvote', 'like', 'yes', 'good', 'true', 1, true]
    end

    def self.false_votes
      ['down', 'downvote', 'dislike', 'no', 'bad', 'false', 0, false]
    end

    ##
    # check is word is a true or bad vote
    # if the word is unknown, then it counts it as a true/good
    # vote.  this exists to allow all voting to be good by default
    def self.word_is_a_vote_for word
      !false_votes.include? word
    end

    def self.default_voting_args
      {
        :vote => true,
      }
    end

  end

end

