require 'acts_as_votable'
require 'spec_helper'

describe ActsAsVotable do

  before(:each) do
    clean_database
  end

  it "should not be votable" do
    NotVotable.should_not be_votable
  end

  it "should be votable" do
    Votable.should be_votable
  end
 
  describe "voting on a votable object" do

    before(:each) do
      clean_database
      @voter = Voter.new(:name => 'i can vote!')
      @voter.save

      @voter2 = Voter.new(:name => 'a new person')
      @voter2.save
      
      @votable = Votable.new(:name => 'a voting model')
      @votable.save
    end

    it "should return an error message when a vote with no voter is saved" do
      @votable.vote.should be 'hello'
    end

    it "should have one vote when saved" do
      @votable.vote :voter => @voter, :vote => 'yes'
      @votable.votes.should == 1
    end
    
    it "should have one vote when voted on twice by the same person" do
      @votable.vote :voter => @voter, :vote => 'yes'
      @votable.vote :voter => @voter, :vote => 'no'
      @votable.votes.should == 1
    end

    it "should have 2 votes when voted on once by two different people" do
      @votable.vote :voter => @voter
      @votable.vote :voter => @voter2
      @votable.votes.should == 2
    end

    it "should have one true vote" do

    end

    it "should have 2 false votes" do

    end

    it "should have been voted on by itself" do
      @votable.vote :voter => @votable, :vote => true
      
    end

    it "should count the vote as registered if this is the voters first vote" do

    end

    it "should not count the vote as being registered if that voter has already voted and the vote has not changed" do

    end
    
    it "should count the vote as registered if the voter has voted and the vote has changed" do

    end

  end


end