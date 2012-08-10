require 'acts_as_votable'
require 'spec_helper'

describe ActsAsVotable::Voter do

  before(:each) do
    clean_database
  end

  it "should not be a voter" do
    NotVotable.should_not be_votable
  end

  it "should be a voter" do
    Votable.should be_votable
  end

  describe "voting by a voter" do

    before(:each) do
      clean_database
      @voter = Voter.new(:name => 'i can vote!')
      @voter.save

      @voter2 = Voter.new(:name => 'a new person')
      @voter2.save

      @votable = Votable.new(:name => 'a voting model')
      @votable.save

      @votable2 = Votable.new(:name => 'a 2nd voting model')
      @votable2.save

      @sti_votable = ChildOfStiVotable.new(:name => 'STI voting model')
      @sti_votable.save
    end

    ["", "sti_"].each do |prefix|
      before(:each) do
        @object = instance_variable_get(:"@#{prefix}votable")
      end

      it "should be voted on after a voter has voted" do
        @object.vote :voter => @voter
        @voter.voted_on?(@object).should be true
      end

      it "should not be voted on if a voter has not voted" do
        @voter.voted_on?(@object).should be false
      end

      it "should be voted as true when a voter has voted true" do
        @object.vote :voter => @voter
        @voter.voted_as_when_voted_for(@object).should be true
      end

      it "should be voted as false when a voter has voted false" do
        @object.vote :voter => @voter, :vote => false
        @voter.voted_as_when_voted_for(@object).should be false
      end

      it "should be voted as nil when a voter has never voted" do
        @voter.voted_as_when_voting_on(@object).should be nil
      end

      it "should return true if voter has voted true" do
        @object.vote :voter => @voter
        @voter.voted_up_on?(@object).should be true
      end

      it "should return false if voter has not voted true" do
        @object.vote :voter => @voter, :vote => false
        @voter.voted_up_on?(@object).should be false
      end

      it "should return true if the voter has voted false" do
        @object.vote :voter => @voter, :vote => false
        @voter.voted_down_on?(@object).should be true
      end

      it "should return false if the voter has not voted false" do
        @object.vote :voter => @voter, :vote => true
        @voter.voted_down_on?(@object).should be false
      end

      it "should provide reserve functionality, voter can vote on votable" do
        @voter.vote :votable => @object, :vote => 'bad'
        @voter.voted_as_when_voting_on(@object).should be false
      end

      it "should allow the voter to vote up a model" do
        @voter.vote_up_for @object
        @object.up_votes.first.voter.should == @voter
        @object.votes.up.first.voter.should == @voter
      end

      it "should allow the voter to vote down a model" do
        @voter.vote_down_for @object
        @object.down_votes.first.voter.should == @voter
        @object.votes.down.first.voter.should == @voter
      end

      it "should allow the voter to unvote a model" do
        @voter.vote_up_for @object
        @voter.unvote_for @object
        @object.find_votes.size.should == 0
        @object.votes.count.should == 0
      end

      it "should get all of the voters votes" do
        @voter.vote_up_for @object
        @voter.find_votes.size.should == 1
        @voter.votes.up.count.should == 1
      end

      it "should get all of the voters up votes" do
        @voter.vote_up_for @object
        @voter.find_up_votes.size.should == 1
        @voter.votes.up.count.should == 1
      end

      it "should get all of the voters down votes" do
        @voter.vote_down_for @object
        @voter.find_down_votes.size.should == 1
        @voter.votes.down.count.should == 1
      end
    end

    it "should get all of the votes votes for a class" do
      @votable.vote :voter => @voter
      @votable2.vote :voter => @voter, :vote => false
      @voter.find_votes_for_class(Votable).size.should == 2
      @voter.votes.for_type(Votable).count.should == 2
    end

    it "should get all of the voters up votes for a class" do
      @votable.vote :voter => @voter
      @votable2.vote :voter => @voter, :vote => false
      @voter.find_up_votes_for_class(Votable).size.should == 1
      @voter.votes.up.for_type(Votable).count.should == 1
    end

    it "should get all of the voters down votes for a class" do
      @votable.vote :voter => @voter
      @votable2.vote :voter => @voter, :vote => false
      @voter.find_down_votes_for_class(Votable).size.should == 1
      @voter.votes.down.for_type(Votable).count.should == 1
    end

    it "should be contained to instances" do
      @voter.vote :votable => @votable, :vote => false
      @voter2.vote :votable => @votable

      @voter.voted_as_when_voting_on(@votable).should be false
    end

  end
end
