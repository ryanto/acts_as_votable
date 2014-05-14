module ActsAsVotable
  module Voter

    def self.included(base)

      # allow user to define these
      aliases = {
        :vote_up_for    => [:likes, :upvotes, :up_votes],
        :vote_down_for  => [:dislikes, :downvotes, :down_votes],
        :unvote_for     => [:unlike, :undislike],
        :voted_on?      => [:voted_for?],
        :voted_up_on?   => [:voted_up_for?, :liked?],
        :voted_down_on? => [:voted_down_for?, :disliked?],
        :voted_as_when_voting_on => [:voted_as_when_voted_on, :voted_as_when_voting_for, :voted_as_when_voted_for],
        :find_up_voted_items   => [:find_liked_items],
        :find_down_voted_items => [:find_disliked_items]
      }

      base.class_eval do

        has_many :votes, :class_name => 'ActsAsVotable::Vote', :as => :voter, :dependent => :destroy do
          def votables
            includes(:votable).map(&:votable)
          end
        end

        aliases.each do |method, links|
          links.each do |new_method|
            alias_method(new_method, method)
          end
        end

      end

    end

    # voting
    def vote args
      args[:votable].vote_by args.merge({:voter => self})
    end

    def vote_up_for model=nil, args={}
      vote :votable => model, :vote_scope => args[:vote_scope], :vote => true
    end

    def vote_down_for model=nil, args={}
      vote :votable => model, :vote_scope => args[:vote_scope], :vote => false
    end

    def unvote_for model, args={}
      model.unvote :voter => self, :vote_scope => args[:vote_scope]
    end

    # results
    def voted_on? votable, args={}
      votes = find_votes(:votable_id => votable.id, :votable_type => votable.class.base_class.name,
                         :vote_scope => args[:vote_scope])
      votes.size > 0
    end

    def voted_up_on? votable, args={}
      votes = find_votes(:votable_id => votable.id, :votable_type => votable.class.base_class.name,
                         :vote_scope => args[:vote_scope], :vote_flag => true)
      votes.size > 0
    end

    def voted_down_on? votable, args={}
      votes = find_votes(:votable_id => votable.id, :votable_type => votable.class.base_class.name,
                         :vote_scope => args[:vote_scope], :vote_flag => false)
      votes.size > 0
    end

    def voted_as_when_voting_on votable, args={}
      vote = find_votes(:votable_id => votable.id, :votable_type => votable.class.base_class.name,
                         :vote_scope => args[:vote_scope]).select(:vote_flag).last
      return nil unless vote
      return vote.vote_flag
    end

    def find_votes extra_conditions = {}
      votes.where(extra_conditions)
    end

    def find_up_votes args={}
      find_votes :vote_flag => true, :vote_scope => args[:vote_scope]
    end

    def find_down_votes args={}
      find_votes :vote_flag => false, :vote_scope => args[:vote_scope]
    end

    def find_votes_for_class klass, extra_conditions = {}
      find_votes extra_conditions.merge({:votable_type => klass.name})
    end

    def find_up_votes_for_class klass, args={}
      find_votes_for_class klass, :vote_flag => true, :vote_scope => args[:vote_scope]
    end

    def find_down_votes_for_class klass, args={}
      find_votes_for_class klass, :vote_flag => false, :vote_scope => args[:vote_scope]
    end

    # Including polymporphic relations for eager loading
    def include_objects
      ActsAsVotable::Vote.includes(:votable)
    end

    def find_voted_items extra_conditions = {}
      options = extra_conditions.merge :voter_id => id, :voter_type => self.class.base_class.name
      include_objects.where(options).collect(&:votable)
    end

    def find_up_voted_items extra_conditions = {}
      find_voted_items extra_conditions.merge(:vote_flag => true)
    end

    def find_down_voted_items extra_conditions = {}
      find_voted_items extra_conditions.merge(:vote_flag => false)
    end

    def get_voted klass, extra_conditions = {}
      klass.joins(:votes_for).merge find_votes(extra_conditions)
    end

    def get_up_voted klass
      klass.joins(:votes_for).merge find_up_votes
    end

    def get_down_voted klass
      klass.joins(:votes_for).merge find_down_votes
    end
  end
end
