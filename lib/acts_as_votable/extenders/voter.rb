# frozen_string_literal: true

module ActsAsVotable
  module Extenders
    module Voter
      def voter?
        false
      end

      def acts_as_voter(*_args)
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
