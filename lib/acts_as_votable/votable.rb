require 'acts_as_votable/helpers/words'

module ActsAsVotable
  module Votable

    include Helpers::Words

    def self.included base
 
      # allow the user to define these himself 
      aliases = {

        :vote_up => [
          :up_by, :upvote_by, :like_by, :liked_by, :vote_by, 
          :up_from, :upvote_from, :upvote_by, :like_from, :liked_from, :vote_from 
        ],

        :vote_down => [
          :down_by, :downvote_by, :dislike_by, :disliked_by,
          :down_from, :downvote_from, :downvote_by, :dislike_by, :disliked_by
        ],

        :up_votes => [
          :true_votes, :ups, :upvotes, :likes, :positives, :for_votes,
        ],

        :down_votes => [
          :false_votes, :downs, :downvotes, :dislikes, :negatives
        ],
        :unvote => [
          :unliked_by, :undisliked_by
        ]
      }

      base.class_eval do

        belongs_to :votable, :polymorphic => true
        has_many   :votes, :class_name => "ActsAsVotable::Vote", :as => :votable do
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
        :votable_id => self.id,
        :votable_type => self.class.base_class.name.to_s
      }
    end

    # voting
    def vote args = {}

      options = {
        :vote => true,
        :vote_scope => nil
      }.merge(args)

      self.vote_registered = false

      if options[:voter].nil?
        return false
      end

      # find the vote
      _votes_ = find_votes({
        :voter_id => options[:voter].id,
        :vote_scope => options[:vote_scope],
        :voter_type => options[:voter].class.name
      })

      if _votes_.count == 0
        # this voter has never voted
        vote = ActsAsVotable::Vote.new(
          :votable => self,
          :voter => options[:voter],
          :vote_scope => options[:vote_scope]
        )
      else
        # this voter is potentially changing his vote
        vote = _votes_.first
      end

      last_update = vote.updated_at

      vote.vote_flag = votable_words.meaning_of(options[:vote])

      if vote.save
        self.vote_registered = true if last_update != vote.updated_at
        update_cached_votes options[:vote_scope]
        return true
      else
        self.vote_registered = false
        return false
      end

    end

    def unvote args = {}
      return false if args[:voter].nil?
      _votes_ = find_votes(:voter_id => args[:voter].id, :vote_scope => args[:vote_scope], :voter_type => args[:voter].class.name)

      return true if _votes_.size == 0
      _votes_.each(&:destroy)
      update_cached_votes args[:vote_scope]
      self.vote_registered = false if votes.count == 0
      return true
    end

    def vote_up voter, options={}
      self.vote :voter => voter, :vote => true, :vote_scope => options[:vote_scope]
    end

    def vote_down voter, options={}
      self.vote :voter => voter, :vote => false, :vote_scope => options[:vote_scope]
    end

    def scope_cache_field field, vote_scope
      return field if vote_scope.nil?

      case field
      when :cached_votes_total=
        "cached_scoped_#{vote_scope}_votes_total="
      when :cached_votes_total
        "cached_scoped_#{vote_scope}_votes_total"
      when :cached_votes_up=
        "cached_scoped_#{vote_scope}_votes_up="
      when :cached_votes_up
        "cached_scoped_#{vote_scope}_votes_up"
      when :cached_votes_down=
        "cached_scoped_#{vote_scope}_votes_down="
      when :cached_votes_down
        "cached_scoped_#{vote_scope}_votes_down" 
      when :cached_votes_score=
        "cached_scoped_#{vote_scope}_votes_score="
      when :cached_votes_score
        "cached_scoped_#{vote_scope}_votes_score"
      end
    end 

    # caching
    def update_cached_votes vote_scope = nil

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

      if self.respond_to?(:cached_votes_score=)
        updates[:cached_votes_score] = (
          (updates[:cached_votes_up] || count_votes_up(true)) -
          (updates[:cached_votes_down] || count_votes_down(true))
        )
      end

      if vote_scope
        if self.respond_to?(scope_cache_field :cached_votes_total=, vote_scope)
          updates[scope_cache_field :cached_votes_total, vote_scope] = count_votes_total(true, vote_scope)
        end

        if self.respond_to?(scope_cache_field :cached_votes_up=, vote_scope)
          updates[scope_cache_field :cached_votes_up, vote_scope] = count_votes_up(true, vote_scope)
        end

        if self.respond_to?(scope_cache_field :cached_votes_down=, vote_scope)
          updates[scope_cache_field :cached_votes_down, vote_scope] = count_votes_down(true, vote_scope)
        end

        if self.respond_to?(scope_cache_field :cached_votes_score=, vote_scope)
          updates[scope_cache_field :cached_votes_score, vote_scope] = (
            (updates[scope_cache_field :cached_votes_up, vote_scope] || count_votes_up(true, vote_scope)) -
            (updates[scope_cache_field :cached_votes_down, vote_scope] || count_votes_down(true, vote_scope))
          )
        end
      end

      if ::ActiveRecord::VERSION::MAJOR < 4
        self.update_attributes(updates, :without_protection => true) if updates.size > 0
      else
        self.update_attributes(updates) if updates.size > 0
      end

    end


    # results
    def find_votes extra_conditions = {}
      votes.where(extra_conditions)
    end

    def up_votes options={}
      find_votes(:vote_flag => true, :vote_scope => options[:vote_scope])
    end

    def down_votes options={}
      find_votes(:vote_flag => false, :vote_scope => options[:vote_scope])
    end


    # counting
    def count_votes_total skip_cache = false, vote_scope = nil
      if !skip_cache && self.respond_to?(scope_cache_field :cached_votes_total, vote_scope)
        return self.send(scope_cache_field :cached_votes_total, vote_scope)
      end
      find_votes(:vote_scope => vote_scope).count
    end

    def count_votes_up skip_cache = false, vote_scope = nil
      if !skip_cache && self.respond_to?(scope_cache_field :cached_votes_up, vote_scope)
        return self.send(scope_cache_field :cached_votes_up, vote_scope)
      end
      up_votes(:vote_scope => vote_scope).count
    end

    def count_votes_down skip_cache = false, vote_scope = nil
      if !skip_cache && self.respond_to?(scope_cache_field :cached_votes_down, vote_scope)
        return self.send(scope_cache_field :cached_votes_down, vote_scope)
      end
      down_votes(:vote_scope => vote_scope).count
    end

    # voters
    def voted_on_by? voter
      votes = find_votes :voter_id => voter.id, :voter_type => voter.class.name
      votes.count > 0
    end

  end
end
