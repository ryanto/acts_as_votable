# frozen_string_literal: true

module ActsAsVotable
  module Extenders
    module Votable
      ALLOWED_CACHEABLE_STRATEGIES = %i[update update_columns]
      ALLOWED_DEPENDENT_STRATEGIES = %i[destroy_all delete_all]

      def votable?
        false
      end

      def acts_as_votable(args = {})
        include ActsAsVotable::Votable

        if args.key?(:cacheable_strategy) && !ALLOWED_CACHEABLE_STRATEGIES.include?(args[:cacheable_strategy])
          raise ArgumentError, args[:cacheable_strategy]
        end
        
        if args.key?(:dependent_strategy) && !ALLOWED_DEPENDENT_STRATEGIES.include?(args[:dependent_strategy])
          raise ArgumentError, args[:dependent_strategy]
        end

        define_method :acts_as_votable_options do
          self.class.instance_variable_get("@acts_as_votable_options")
        end

        class_eval do
          @acts_as_votable_options = {
            cacheable_strategy: :update,
            dependent_strategy: :delete_all
          }.merge(args)

          def self.votable?
            true
          end
        end
      end
    end
  end
end
