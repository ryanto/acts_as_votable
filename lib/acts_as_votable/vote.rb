# frozen_string_literal: true

require "acts_as_votable/helpers/words"

module ActsAsVotable
  class Vote < ::ActiveRecord::Base
    include Helpers::Words

    if defined?(ProtectedAttributes)
      attr_accessible :votable_id, :votable_type,
        :voter_id, :voter_type,
        :votable, :voter,
        :vote_flag, :vote_scope
    end

    belongs_to :votable, polymorphic: true
    belongs_to :voter, polymorphic: true

    scope :up, -> { where(vote_flag: true) }
    scope :down, -> { where(vote_flag: false) }
    scope :for_type, ->(klass) { where(votable_type: klass.to_s) }
    scope :by_type, ->(klass) { where(voter_type: klass.to_s) }

    validates_presence_of :votable_id
    validates_presence_of :voter_id
  end
end
