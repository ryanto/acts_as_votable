# frozen_string_literal: true

$LOAD_PATH << File.join(File.dirname(__FILE__), "..", "lib")

require "simplecov"
require "acts_as_votable"
require "factory_bot"
require_relative "support/database"

Dir["./spec/shared_example/**/*.rb"].sort.each { |f| require f }
Dir["./spec/support/**/*.rb"].sort.each { |f| require f }

SimpleCov.start
