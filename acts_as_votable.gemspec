# -*- encoding: utf-8 -*-
# frozen_string_literal: true

$:.push File.expand_path("../lib", __FILE__)
require "acts_as_votable/version"

Gem::Specification.new do |s|
  s.name        = "acts_as_votable"
  s.version     = ActsAsVotable::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ryan"]
  s.email       = ["ryanto"]
  s.homepage    = "http://rubygems.org/gems/acts_as_votable"
  s.summary     = "Rails gem to allowing records to be votable"
  s.description = "Rails gem to allowing records to be votable"
  s.license     = "MIT"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec", "~> 3.6"
  s.add_development_dependency "sqlite3", "~> 1.3.6"
  s.add_development_dependency "rubocop", "~> 0.49.1"
  s.add_development_dependency "simplecov", "~> 0.15.0"
  s.add_development_dependency "appraisal", "~> 2.2"
  s.add_development_dependency "factory_bot", "~> 4.8"
end
