module ActsAsVotable
  module Voter

    def self.included(base)
      base.send :include, ActsAsVotable::Voter::InstanceMethods
    end


    module ClassMethods
    end

    module InstanceMethods

      def default_conditions
        {
          :voter_id => self.id,
          :voter_type => self.class.name
        }
      end

      # voting
      def vote args
        args[:votable].vote args.merge({:voter => self})
      end

      def vote_up_for model
        vote :votable => model, :vote => true
      end

      def vote_down_for model
        vote :votable => model, :vote => false
      end

      # results
      def voted_on? votable
        votes = find_votes(:votable_id => votable.id, :votable_type => votable.class.name)
        votes.size > 0
      end
      alias :voted_for? :voted_on?

      def voted_as_when_voting_on votable
        votes = find_votes(:votable_id => votable.id, :votable_type => votable.class.name)
        return nil if votes.size == 0
        return votes.first.vote_flag
      end
      alias :voted_as_when_voting_for :voted_as_when_voting_on

      
      def find_votes extra_conditions = {}
        ActsAsVotable::Vote.find(:all, :conditions => default_conditions.merge(extra_conditions))
      end
      alias :votes :find_votes

      def find_up_votes
        find_votes :vote_flag => true
      end

      def find_down_votes
        find_votes :vote_flag => false
      end

      def find_votes_for_class klass, extra_conditions = {}
        find_votes extra_conditions.merge({:votable_type => klass.name})
      end

      def find_up_votes_for_class klass
        find_votes_for_class klass, :vote_flag => true
      end

      def find_down_votes_for_class klass
        find_votes_for_class klass, :vote_flag => false
      end

    end

  end
end