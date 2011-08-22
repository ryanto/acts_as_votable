require 'active_record'
require 'active_support/inflector'

$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'acts_as_votable/init/init'
require 'acts_as_votable/init/votable'
require 'acts_as_votable/init/voter'
require 'acts_as_votable/searchable'
require 'acts_as_votable/votable'
require 'acts_as_votable/voter'
require 'acts_as_votable/alias'

module ActsAsVotable

  if defined?(ActiveRecord::Base)
    require 'acts_as_votable/vote'
    ActiveRecord::Base.extend ActsAsVotable::Init::Votable
    ActiveRecord::Base.extend ActsAsVotable::Init::Voter
  end

end
