module ActsAsVotable
  module Extenders

    module Voter

      def voter?
        false
      end

      def acts_as_voter(*args)
        require 'acts_as_votable/voter'
        include ActsAsVotable::Voter

        class_eval do
          def self.voter?
            true
          end
        end

      end

    end
  end
end
