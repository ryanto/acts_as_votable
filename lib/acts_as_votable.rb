require 'active_record'

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

    end




  end



  # votes table
  

 
  if defined?(ActiveRecord::Base)
    require 'acts_as_votable/vote'
    ActiveRecord::Base.extend ActsAsVotable::Votable
    #ActiveRecord::Base.send :include, ActsAsTaggableOn::Tagger
  end


end
