module ActsAsVotable::Init
  
  module Votable

    def votable?
      false
    end

    def acts_as_votable(*args)

      class_eval do
        belongs_to :votable, :polymorphic => true

        def self.votable?
          true
        end

        include ActsAsVotable::Votable

      end

      # aliasing
      ActsAsVotable::Alias::words_to_alias self, ActsAsVotable::Vote.true_votes, :count_votes_true
      ActsAsVotable::Alias::words_to_alias self, ActsAsVotable::Vote.false_votes, :count_votes_false

    end


  end

end