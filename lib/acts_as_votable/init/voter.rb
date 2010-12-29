module ActsAsVotable::Init

  # voter
  module Voter

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

end