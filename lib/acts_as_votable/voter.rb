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

      def total_votes_for_class klass
        find_votes({:votable_type => klass.name}).size
      end

      def vote args
        args[:votable].vote args.merge({:voter => self})
      end

    end

  end
end