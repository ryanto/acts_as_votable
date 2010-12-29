require 'active_record'
require 'active_support/inflector'

$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'acts_as_votable/core'

module ActsAsVotable

  # votable
  module Votable

    def votable?
      false
    end

    def acts_as_votable(*args)

      class_eval do
        belongs_to :votable, :polymorphic => true

        def self.votable?
          true
        end

        include ActsAsVotable::Core

      end

      # aliasing
      ActsAsVotable::Alias::words_to_alias self, ActsAsVotable::Vote.true_votes, :count_true_votes
      ActsAsVotable::Alias::words_to_alias self, ActsAsVotable::Vote.false_votes, :count_false_votes

    end




  end

  module Alias

    def self.words_to_alias object, words, function
      words.each do |word|
        function = word.to_s.pluralize.to_sym
        if !object.respond_to?(function)
          object.class_eval{ alias function :count_votes_true }
        end
      end
    end

  end
 
  if defined?(ActiveRecord::Base)
    require 'acts_as_votable/vote'
    ActiveRecord::Base.extend ActsAsVotable::Votable
    #ActiveRecord::Base.send :include, ActsAsTaggableOn::Tagger
  end


end
