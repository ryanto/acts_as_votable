require 'acts_as_votable/helpers/words'

module ActsAsVotable
  module Votable

    include Helpers::Words

    def self.included base

      # allow the user to define these himself
      aliases = {

        :vote_up => [
          :up_by, :upvote_by, :like_by, :liked_by, 
          :up_from, :upvote_from, :upvote_by, :like_from, :liked_from, :vote_from
        ],

        :vote_down => [
          :down_by, :downvote_by, :dislike_by, :disliked_by,
          :down_from, :downvote_from, :downvote_by, :dislike_by, :disliked_by
        ],

        :get_up_votes => [
          :get_true_votes, :get_ups, :get_upvotes, :get_likes, :get_positives, :get_for_votes,
        ],

        :get_down_votes => [
          :get_false_votes, :get_downs, :get_downvotes, :get_dislikes, :get_negatives
        ],
        :unvote_by => [
          :unvote_up, :unvote_down, :unliked_by, :undisliked_by
        ]
      }

      base.class_eval do
        has_many :votes_for, :class_name => 'ActsAsVotable::Vote', :as => :votable, :dependent => :destroy do
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
    def vote_by args = {}

      options = {
        :vote => true,
        :vote_scope => nil
      }.merge(args)

      self.vote_registered = false

      if options[:voter].nil?
        return false
      end

      # find the vote
      _votes_ = find_votes_for({
        :voter_id => options[:voter].id,
        :vote_scope => options[:vote_scope],
        :voter_type => options[:voter].class.base_class.name
      })

      if _votes_.count == 0 or options[:duplicate]
        # this voter has never voted
        vote = ActsAsVotable::Vote.new(
          :votable => self,
          :voter => options[:voter],
          :vote_scope => options[:vote_scope]
        )
      else
        # this voter is potentially changing his vote
        vote = _votes_.last
      end

      last_update = vote.updated_at

      vote.vote_flag = votable_words.meaning_of(options[:vote])

      #Allowing for a vote_weight to be associated with every vote. Could change with every voter object
      vote.vote_weight = (options[:vote_weight].to_i if options[:vote_weight].present?) || 1

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
      _votes_ = find_votes_for(:voter_id => args[:voter].id, :vote_scope => args[:vote_scope], :voter_type => args[:voter].class.base_class.name)

      return true if _votes_.size == 0
      _votes_.each(&:destroy)
      update_cached_votes args[:vote_scope]
      self.vote_registered = false if votes_for.count == 0
      return true
    end

    def vote_up voter, options={}
      self.vote_by :voter => voter, :vote => true, :vote_scope => options[:vote_scope], :vote_weight => options[:vote_weight]
    end

    def vote_down voter, options={}
      self.vote_by :voter => voter, :vote => false, :vote_scope => options[:vote_scope], :vote_weight => options[:vote_weight]
    end

    def unvote_by  voter, options = {}
      self.unvote :voter => voter, :vote_scope => options[:vote_scope] #Does not need vote_weight since the votes_for are anyway getting destroyed
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
      when :cached_weighted_total
        "cached_weighted_#{vote_scope}_total"
      when :cached_weighted_total=
        "cached_weighted_#{vote_scope}_total="
      when :cached_weighted_score
        "cached_weighted_#{vote_scope}_score"
      when :cached_weighted_score=
        "cached_weighted_#{vote_scope}_score="
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

      if self.respond_to?(:cached_weighted_total=)
        updates[:cached_weighted_total] = weighted_total(true)
      end

      if self.respond_to?(:cached_weighted_score=)
        updates[:cached_weighted_score] = weighted_score(true)
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

        if self.respond_to?(scope_cache_field :cached_weighted_total=, vote_scope)
          updates[scope_cache_field :cached_weighted_total, vote_scope] = weighted_total(true, vote_scope)
        end

        if self.respond_to?(scope_cache_field :cached_weighted_score=, vote_scope)
          updates[scope_cache_field :cached_weighted_score, vote_scope] = weighted_score(true, vote_scope)
        end

        if self.respond_to?(scope_cache_field :cached_votes_score=, vote_scope)
          updates[scope_cache_field :cached_votes_score, vote_scope] = (
            (updates[scope_cache_field :cached_votes_up, vote_scope] || count_votes_up(true, vote_scope)) -
            (updates[scope_cache_field :cached_votes_down, vote_scope] || count_votes_down(true, vote_scope))
          )
        end
      end

      if (::ActiveRecord::VERSION::MAJOR == 3) && (::ActiveRecord::VERSION::MINOR != 0)
        self.update_attributes(updates, :without_protection => true) if updates.size > 0
      else
        self.update_attributes(updates) if updates.size > 0
      end

    end


    # results
    def find_votes_for extra_conditions = {}
      votes_for.where(extra_conditions)
    end

    def get_up_votes options={}
      find_votes_for(:vote_flag => true, :vote_scope => options[:vote_scope])
    end

    def get_down_votes options={}
      find_votes_for(:vote_flag => false, :vote_scope => options[:vote_scope])
    end


    # counting
    def count_votes_total skip_cache = false, vote_scope = nil
      if !skip_cache && self.respond_to?(scope_cache_field :cached_votes_total, vote_scope)
        return self.send(scope_cache_field :cached_votes_total, vote_scope)
      end
      find_votes_for(:vote_scope => vote_scope).count
    end

    def count_votes_up skip_cache = false, vote_scope = nil
      if !skip_cache && self.respond_to?(scope_cache_field :cached_votes_up, vote_scope)
        return self.send(scope_cache_field :cached_votes_up, vote_scope)
      end
      get_up_votes(:vote_scope => vote_scope).count
    end

    def count_votes_down skip_cache = false, vote_scope = nil
      if !skip_cache && self.respond_to?(scope_cache_field :cached_votes_down, vote_scope)
        return self.send(scope_cache_field :cached_votes_down, vote_scope)
      end
      get_down_votes(:vote_scope => vote_scope).count
    end

    def weighted_total skip_cache = false, vote_scope = nil
      if !skip_cache && self.respond_to?(scope_cache_field :cached_weighted_total, vote_scope)
        return self.send(scope_cache_field :cached_weighted_total, vote_scope)
      end
      ups = get_up_votes(:vote_scope => vote_scope).sum(:vote_weight)
      downs = get_down_votes(:vote_scope => vote_scope).sum(:vote_weight)
      ups + downs
    end

    def weighted_score skip_cache = false, vote_scope = nil
      if !skip_cache && self.respond_to?(scope_cache_field :cached_weighted_score, vote_scope)
        return self.send(scope_cache_field :cached_weighted_score, vote_scope)
      end
      ups = get_up_votes(:vote_scope => vote_scope).sum(:vote_weight)
      downs = get_down_votes(:vote_scope => vote_scope).sum(:vote_weight)
      ups - downs
    end

    # voters
    def voted_on_by? voter
      votes = find_votes_for :voter_id => voter.id, :voter_type => voter.class.base_class.name
      votes.count > 0
    end

  end
end
