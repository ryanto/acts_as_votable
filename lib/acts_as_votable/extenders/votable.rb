# frozen_string_literal: true

module ActsAsVotable
  module Extenders
    module Votable
      ALLOWED_CACHEABLE_STRATEGIES = %i[update update_columns]

      def votable?
        false
      end

      def acts_as_votable(args = {})
        include ActsAsVotable::Votable

        if args.key?(:cacheable_strategy) && !ALLOWED_CACHEABLE_STRATEGIES.include?(args[:cacheable_strategy])
          raise ArgumentError, args[:cacheable_strategy]
        end

        define_method :acts_as_votable_options do
          self.class.instance_variable_get("@acts_as_votable_options")
        end

        class_eval do
          @acts_as_votable_options = {
            cacheable_strategy: :update
          }.merge(args)

          def self.votable?
            true
          end
        end
      end
    end
  end
end
