module ActsAsVotable::Extenders

  # voter
  module Voter

    def voter?
      false
    end

    def acts_as_voter(*args)

      include ActsAsVotable::Voter

      class_eval do
        def self.voter?
          true
        end
      end

    end

  end

end
