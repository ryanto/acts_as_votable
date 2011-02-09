module ActsAsVotable::Init

  # voter
  module Voter

    def voter?
      false
    end

    def acts_as_voter(*args)

      class_eval do
        belongs_to :voter, :polymorphic => true

        def self.voter?
          true
        end

        include ActsAsVotable::Voter

        ActsAsVotable::Alias::words_to_alias self, %w(likes upvotes), :vote_up_for
        ActsAsVotable::Alias::words_to_alias self, %w(dislikes downvotes), :vote_down_for

      end

    end

  end

end