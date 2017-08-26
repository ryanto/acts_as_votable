# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in acts_as_votable.gemspec
gemspec

env_rails = ENV["RAILS_VERSION"] || "default"
def set_rails_version(env_rails)
  case env_rails
  when "master"
    { github: "rails/rails" }
  when "default"
    "~> 4.2.9"
  else
    "~> #{env_rails}"
  end
end

gem "rails", set_rails_version(env_rails)
