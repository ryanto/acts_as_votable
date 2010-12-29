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

      def vote_registered?
        return self.vote_registered
      end

      def default_conditions
        {
          :votable_id => self.id,
          :votable_type => self.class.name
        }
      end

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

      # caching
      def update_cached_votes

        updates = {}

        if self.respond_to?(:cached_votes_total=)
          updates[:cached_votes_total] = count_votes_total(true)
        end

        if self.respond_to?(:cached_votes_up=)
          updates[:cached_votes_up] = count_votes_true(true)
        end

        if self.respond_to?(:cached_votes_down=)
          updates[:cached_votes_down] = count_votes_false(true)
        end

        self.update_attributes(updates) if updates.size > 0

      end


      # results
      def find_votes extra_conditions = {}
        ActsAsVotable::Vote.find(:all, :conditions => default_conditions.merge(extra_conditions))
      end

      def count_votes_total skip_cache = false
        if !skip_cache && self.respond_to?(:cached_votes_total)
          return self.send(:cached_votes_total)
        end
        find_votes.size
      end
      alias :votes :count_votes_total

      def count_votes_true skip_cache = false
        if !skip_cache && self.respond_to?(:cached_votes_up)
          return self.send(:cached_votes_up)
        end
        find_votes(:vote_flag => true).size
      end

      def count_votes_false skip_cache = false
        if !skip_cache && self.respond_to?(:cached_votes_down)
          return self.send(:cached_votes_down)
        end
        find_votes(:vote_flag => false).size
      end


    end

  end
end