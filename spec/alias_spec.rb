require 'acts_as_votable'
require 'spec_helper'

describe ActsAsVotable::Alias do

  before(:each) do
    clean_database
    @votable = Votable.new(:name => 'votable with aliases')
    @votable.save
  end

  it "should alias a bunch of functions" do
    @votable.respond_to?(:upvotes).should be true
    @votable.respond_to?(:ups).should be true
    @votable.respond_to?(:dislikes).should be true
  end

  it "should only alias voting words that are strings" do
    @votable.respond_to?('1s'.to_sym).should be false
  end





end
