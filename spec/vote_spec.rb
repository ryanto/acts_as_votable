require 'acts_as_votable'
require 'spec_helper'

describe ActsAsVotable::Vote do

  it "should know that like is a true vote" do
    ActsAsVotable::Vote.true_votes.should include "like"
  end

  it "should know that bad is a false vote" do
    ActsAsVotable::Vote.false_votes.should include "bad"
  end

  it "should be a vote for true when word is good" do
    ActsAsVotable::Vote.word_is_a_vote_for('good').should be true
  end

  it "should be a vote for false when word is down" do
    ActsAsVotable::Vote.word_is_a_vote_for('down').should be false
  end

  it "should be a vote for true when the word is unknown" do
    ActsAsVotable::Vote.word_is_a_vote_for('lsdhklkadhfs').should be true
  end

  it "should have vote=>true in the default voting args" do
    ActsAsVotable::Vote.default_voting_args[:vote].should be true
  end





end
