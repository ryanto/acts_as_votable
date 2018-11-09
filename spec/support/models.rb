# frozen_string_literal: true

class Voter < ActiveRecord::Base
  acts_as_voter
end

class NotVoter < ActiveRecord::Base
end

class Votable < ActiveRecord::Base
  acts_as_votable
  validates_presence_of :name
end

class VotableVoter < ActiveRecord::Base
  acts_as_votable
  acts_as_voter
end

class StiVotable < ActiveRecord::Base
  acts_as_votable
end

class ChildOfStiVotable < StiVotable
end

class StiNotVotable < ActiveRecord::Base
  validates_presence_of :name
end

class ChildOfStiNotVotable < StiNotVotable
  acts_as_votable
end

class NotVotable < ActiveRecord::Base
end

class VotableCache < ActiveRecord::Base
  acts_as_votable
  validates_presence_of :name
end

class VotableCacheUpdateAttributes < VotableCache
  acts_as_votable cacheable_strategy: :update_attributes
end

class VotableCacheUpdateColumns < VotableCache
  acts_as_votable cacheable_strategy: :update_columns
end

class ABoringClass
  def self.hw
    "hello world"
  end
end
