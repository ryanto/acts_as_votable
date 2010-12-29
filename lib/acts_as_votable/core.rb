module ActsAsVotable
  module Core

    def self.included(base)
      base.send :include, ActsAsVotable::Core::InstanceMethods
      #base.extend ActsAsVotable::Core::ClassMethods
      
    end


    module ClassMethods
      

    end

    module InstanceMethods

      attr_accessor :vote_registered

      def default_conditions
        {
          :votable_id => self.id,
          :votable_type => self.class.name
        }
      end

      def vote args

        options = Vote.default_voting_args.merge(args)
        vote_registered = false

        # find the vote
        votes = find_votes({
          :voter_id => options[:voter].id,
          :voter_type => options[:voter].class.name
        })

        if votes.count == 0
          # this voter has never voted
          vote = Vote.new(
            :votable => self,
            :voter => options[:voter]
          )
        else
          # this voter is potentially changing his vote
          vote = votes.first
        end

        last_update = vote.updated_at

        vote.vote_flag = Vote.word_is_a_vote_for(options[:vote])

        last_update = vote.updated_at

        if vote.save
          vote_registered = true if last_update != vote.updated_at
          #update_cached_votes
        else
          vote_registered = false
        end

        

      end

      # results
      def find_votes extra_conditions = {}
        Vote.find(:all, :conditions => default_conditions.merge(extra_conditions))
      end

      def count_votes_total extra_conditions = {}
        find_votes(extra_conditions).size
      end
      alias :votes :count_votes_total
      alias :total_votes :count_votes_total
      alias :count_votes :count_votes_total

      def count_votes_true
        count_votes_total :vote_flag => true
      end
      alias :upvotes :count_votes_true
      alias :likes :count_votes_true

      def count_votes_false
        count_votes_total :vote_flag => false
      end
      alias :downvotes :count_votes_false
      alias :dislikes :count_votes_false

      

    end

  end
end