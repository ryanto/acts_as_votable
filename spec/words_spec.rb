require 'acts_as_votable'
require 'spec_helper'

describe ActsAsVotable::Helpers::Words do

  before :each do
    @vote = ActsAsVotable::Vote.new
  end

  it "should know that like is a true vote" do
    @vote.votable_words.that_mean_true.should include "like"
  end

  it "should know that bad is a false vote" do
    @vote.votable_words.that_mean_false.should include "bad"
  end

  it "should be a vote for true when word is good" do
    @vote.votable_words.meaning_of('good').should be true
  end

  it "should be a vote for false when word is down" do
    @vote.votable_words.meaning_of('down').should be false
  end

  it "should be a vote for true when the word is unknown" do
    @vote.votable_words.meaning_of('lsdhklkadhfs').should be true
  end

end
