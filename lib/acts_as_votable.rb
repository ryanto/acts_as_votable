# frozen_string_literal: true

require "active_record"
require "active_support/inflector"
require "active_support/dependencies/autoload"

$LOAD_PATH.unshift(File.dirname(__FILE__))

module ActsAsVotable
  extend ActiveSupport::Autoload

  autoload :Votable
  autoload :Vote
  autoload :Voter
  autoload :Cacheable
  autoload :Extenders
  autoload :Helpers

  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.extend ActsAsVotable::Extenders::Votable
    ActiveRecord::Base.extend ActsAsVotable::Extenders::Voter
  end
end

ActiveSupport.on_load(:action_controller) do
  include ActsAsVotable::Extenders::Controller
end
