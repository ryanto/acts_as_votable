# frozen_string_literal: true

module ActsAsVotable
  module Extenders
    extend ActiveSupport::Autoload

    autoload :"Votable"
    autoload :"Voter"
    autoload :"Controller"
  end
end