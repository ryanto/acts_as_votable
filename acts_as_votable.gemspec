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

  s.rubyforge_project = "acts_as_votable"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec"
  s.add_development_dependency "sqlite3", "~> 1.3.9"
  s.add_development_dependency "rubocop"
  s.add_development_dependency "pry-byebug"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "guard-rspec"
end
