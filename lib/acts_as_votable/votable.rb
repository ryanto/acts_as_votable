# frozen_string_literal: true

require "acts_as_votable/helpers/words"

module ActsAsVotable
  module Votable
    include Helpers::Words
    include Cacheable

    def self.included(base)
      # allow the user to define these himself
      aliases = {

        vote_up: [
          :up_by, :upvote_by, :like_by, :liked_by,
          :up_from, :upvote_from, :upvote_by, :like_from, :liked_from, :vote_from
        ],

        vote_down: [
          :down_by, :downvote_by, :dislike_by, :disliked_by,
          :down_from, :downvote_from, :downvote_by, :dislike_by, :disliked_by
        ],

        get_up_votes: [
          :get_true_votes, :get_ups, :get_upvotes, :get_likes, :get_positives, :get_for_votes,
        ],

        get_down_votes: [
          :get_false_votes, :get_downs, :get_downvotes, :get_dislikes, :get_negatives
        ],
        unvote_by: [
          :unvote_up, :unvote_down, :unliked_by, :undisliked_by
        ]
      }

      base.class_eval do
        has_many :votes_for, class_name: "ActsAsVotable::Vote", as: :votable, dependent: :delete_all do
          def voters
            includes(:voter).map(&:voter)
          end
        end

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
        votable_id: self.id,
        votable_type: self.class.base_class.name.to_s
      }
    end

    # voting
    def vote_by(args = {})
      return false if args[:voter].nil?

      options = { vote: true, vote_scope: nil }.merge(args)

      self.vote_registered = false

      # find the vote
      votes = find_votes_by(options[:voter], options[:vote_scope])

      if options[:duplicate] || !votes.exists?
        # this voter has never voted
        vote = ActsAsVotable::Vote.new(
          votable: self,
          voter: options[:voter],
          vote_scope: options[:vote_scope]
        )
      else
        # this voter is potentially changing his vote
        vote = votes.last
      end

      last_update = vote.updated_at

      vote.vote_flag = votable_words.meaning_of(options[:vote])

      #Allowing for a vote_weight to be associated with every vote. Could change with every voter object
      vote.vote_weight = (options[:vote_weight].to_i if options[:vote_weight].present?) || 1

      vote_saved = false
      ActiveRecord::Base.transaction do
        self.vote_registered = false
        vote_saved = vote.save
        if vote_saved
          self.vote_registered = true if last_update != vote.updated_at
          update_cached_votes(options[:vote_scope])
        end
      end
      vote_saved
    end

    def unvote(args = {})
      return false if args[:voter].nil?
      votes = find_votes_by(args[:voter], args[:vote_scope])

      ActiveRecord::Base.transaction do
        deleted_count = votes.delete_all
        update_cached_votes(args[:vote_scope]) if deleted_count > 0
      end
      self.vote_registered = false
      return true
    end

    def vote_up(voter, options = {})
      self.vote_by voter: voter, vote: true, vote_scope: options[:vote_scope], vote_weight: options[:vote_weight]
    end

    def vote_down(voter, options = {})
      self.vote_by voter: voter, vote: false, vote_scope: options[:vote_scope], vote_weight: options[:vote_weight]
    end

    def unvote_by(voter, options = {})
      self.unvote voter: voter, vote_scope: options[:vote_scope] #Does not need vote_weight since the votes_for are anyway getting destroyed
    end

    # results
    def find_votes_for(extra_conditions = {})
      votes_for.where(extra_conditions)
    end

    def find_votes_by(voter, vote_scope)
      find_votes_for(voter_id:   voter.id,
                     vote_scope: vote_scope,
                     voter_type: voter.class.base_class.name)
    end

    def get_up_votes(options = {})
      vote_scope_hash = scope_or_empty_hash(options[:vote_scope])
      find_votes_for({ vote_flag: true }.merge(vote_scope_hash))
    end

    def get_down_votes(options = {})
      vote_scope_hash = scope_or_empty_hash(options[:vote_scope])
      find_votes_for({ vote_flag: false }.merge(vote_scope_hash))
    end

    # voters
    def voted_on_by?(voter)
      votes = find_votes_for voter_id: voter.id, voter_type: voter.class.base_class.name
      votes.exists?
    end

    def voted_up_by?(voter)
      votes = find_votes_for(voter_id: voter.id,
                             vote_flag: true,
                             voter_type: voter.class.base_class.name)
      votes.exists?
    end

    def voted_down_by?(voter)
      votes = find_votes_for(voter_id: voter.id,
                             vote_flag: false,
                             voter_type: voter.class.base_class.name)
      votes.exists?
    end

    private

    def scope_or_empty_hash(vote_scope)
      vote_scope ? { vote_scope: vote_scope } : {}
    end
  end
end
