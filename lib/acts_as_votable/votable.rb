module ActsAsVotable
  module Votable

    def self.included base
 
      # allow the user to define these himself 
      aliases = {

        :vote_up => [
          :up_by, :upvote_by, :like_by, :liked_by, :vote_by, 
          :up_from, :upvote_from, :like_from, :liked_from, :vote_from 
        ],

        :vote_down => [
          :down_by, :downvote_by, :dislike_by, :disliked_by,
          :down_from, :downvote_by, :dislike_by, :disliked_by
        ],

        :up_votes => [
          :true_votes, :ups, :upvotes, :likes, :positives, :for_votes,
        ],

        :down_votes => [
          :false_votes, :downs, :downvotes, :dislikes, :negatives
        ]

      }

      base.class_eval do

        belongs_to :votable, :polymorphic => true

        aliases.each do |method, links|
          links.each do |new_method|
            alias_method(new_method, method)
          end
        end

      end
    end

    attr_accessor :vote_registered

    def vote_registered?
      return self.vote_registered
    end

    def default_conditions
      {
        :votable_id => self.id,
        :votable_type => self.class.name
      }
    end

    # voting
    def vote args = {}

      options = ActsAsVotable::Vote.default_voting_args.merge(args)
      self.vote_registered = false

      if options[:voter].nil?
        return false
      end

      # find the vote
      votes = find_votes({
          :voter_id => options[:voter].id,
          :voter_type => options[:voter].class.name
        })

      if votes.count == 0
        # this voter has never voted
        vote = ActsAsVotable::Vote.new(
          :votable => self,
          :voter => options[:voter]
        )
      else
        # this voter is potentially changing his vote
        vote = votes.first
      end

      last_update = vote.updated_at

      vote.vote_flag = ActsAsVotable::Vote.word_is_a_vote_for(options[:vote])

      if vote.save
        self.vote_registered = true if last_update != vote.updated_at
        update_cached_votes
        return true
      else
        self.vote_registered = false
        return false
      end

     
    end

    def vote_up voter
      self.vote :voter => voter, :vote => true
    end

    def vote_down voter
      self.vote :voter => voter, :vote => false
    end

    # caching
    def update_cached_votes

      updates = {}

      if self.respond_to?(:cached_votes_total=)
        updates[:cached_votes_total] = count_votes_total(true)
      end

      if self.respond_to?(:cached_votes_up=)
        updates[:cached_votes_up] = count_votes_up(true)
      end

      if self.respond_to?(:cached_votes_down=)
        updates[:cached_votes_down] = count_votes_down(true)
      end

      self.update_attributes(updates) if updates.size > 0

    end


    # results
    def find_votes extra_conditions = {}
      ActsAsVotable::Vote.find(:all, :conditions => default_conditions.merge(extra_conditions))
    end
    alias :votes :find_votes

    def up_votes
      find_votes(:vote_flag => true)
    end

    def down_votes
      find_votes(:vote_flag => false)
    end


    # counting
    def count_votes_total skip_cache = false
      if !skip_cache && self.respond_to?(:cached_votes_total)
        return self.send(:cached_votes_total)
      end
      find_votes.size
    end

    def count_votes_up skip_cache = false
      if !skip_cache && self.respond_to?(:cached_votes_up)
        return self.send(:cached_votes_up)
      end
      up_votes.size
    end

    def count_votes_down skip_cache = false
      if !skip_cache && self.respond_to?(:cached_votes_down)
        return self.send(:cached_votes_down)
      end
      down_votes.size
    end

    # voters
    def voted_on_by? voter
      votes = find_votes :voter_id => voter.id, :voter_type => voter.class.name
      votes.size > 0
    end

  end
end
