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

      # voting
      ActsAsVotable::Alias::words_to_alias self, %w(up_by upvote_by like_by liked_by vote_by), :vote_up
      ActsAsVotable::Alias::words_to_alias self, %w(up_from upvote_from like_from liked_from vote_from), :vote_up
      ActsAsVotable::Alias::words_to_alias self, %w(down_by downvote_by dislike_by disliked_by), :vote_down
      ActsAsVotable::Alias::words_to_alias self, %w(down_from downvote_from dislike_from disliked_from), :vote_down

      # finding
      ActsAsVotable::Alias::words_to_alias self, %w(true_votes ups upvotes likes positives), :up_votes
      ActsAsVotable::Alias::words_to_alias self, %w(false_votes downs downvotes dislikes negatives), :down_votes

    end


  end

end