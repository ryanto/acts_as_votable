module ActsAsVotable::Extenders

  module Votable

    def votable?
      false
    end

    def acts_as_votable

      include ActsAsVotable::Votable

      class_eval do
        def self.votable?
          true
        end
      end

    end


  end

end
