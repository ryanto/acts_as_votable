source 'https://rubygems.org'

# Specify your gem's dependencies in acts_as_votable.gemspec
gemspec

rails_version = ENV['RAILS_VERSION'] || 'default'

rails = case rails_version
when 'master'
  { :github => 'rails/rails'}
when 'default'
  '~> 4.2.9'
else
  "~> #{rails_version}"
end

gem 'rails', rails
