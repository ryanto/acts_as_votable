require 'acts_as_votable'
require 'spec_helper'

describe ActsAsVotable do

  before(:each) do
    #clean_database
  end

  it "should not be votable" do
    NotVotableModel.should_not be_votable
  end

  it "should be votable" do
    VotableModel.should be_votable
  end
 
  describe "Voting on a votable object" do

    before(:each) do

      #clean_database


    end

    it "should return an error message when a vote with no voter is saved" do
      votable_model = VotableModel.new(:name => 'a voting model')

    end

    it "should have one vote when saved" do
      votable_model = VotableModel.new(:name => 'a voting model')
      votable_model.save
      votable_model.vote :voter => votable_model, :vote => 'yes'
      votable_model.count_votes_total.should == 1
    end

    it "should have been voted on by itself" do

    end

    it "should count the vote as registered if this is the voters first vote" do

    end

    it "should not count the vote as being registered if that voter has already voted and the vote has not changed" do

    end
    
    it "should count the vote as registered if the voter has voted and the vote has changed" do

    end

  end


end