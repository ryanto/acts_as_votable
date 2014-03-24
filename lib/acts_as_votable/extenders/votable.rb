module ActsAsVotable
  module Extenders

    module Votable

      def votable?
        false
      end

      def acts_as_votable(opts = {})
        require 'acts_as_votable/votable'
        include ActsAsVotable::Votable

        class_eval do
          
          class_attribute :votable_options
          
          self.votable_options = opts.with_indifferent_access

          def self.votable?
            true
          end
        end

      end

    end

  end
end
