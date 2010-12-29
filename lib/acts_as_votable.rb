require 'active_record'
require 'active_support/inflector'

$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'acts_as_votable/votable'
require 'acts_as_votable/voter'

module ActsAsVotable

  # votable
  module AcceptVotable

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
      ActsAsVotable::Alias::words_to_alias self, ActsAsVotable::Vote.true_votes, :count_votes_true
      ActsAsVotable::Alias::words_to_alias self, ActsAsVotable::Vote.false_votes, :count_votes_false

    end

  end

  # votable
  module AcceptVoter

    def voter?
      false
    end

    def acts_as_voter(*args)

      class_eval do
        belongs_to :voter, :polymorphic => true

        def self.voter?
          true
        end

        include ActsAsVotable::Voter

      end

    end

  end


  module Alias

    def self.words_to_alias object, words, call_function
      words.each do |word|
        if word.is_a?(String)
          function = word.pluralize.to_sym
          if !object.respond_to?(function)
            object.send(:alias_method, function, call_function)
          end
        end
      end
    end

  end
 
  if defined?(ActiveRecord::Base)
    require 'acts_as_votable/vote'
    ActiveRecord::Base.extend ActsAsVotable::AcceptVotable
    ActiveRecord::Base.extend ActsAsVotable::AcceptVoter
  end


end
