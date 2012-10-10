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
    end

    it "should be voted on after a voter has voted" do
      @votable.vote :voter => @voter
      @voter.voted_on?(@votable).should be true
    end

    it "should not be voted on if a voter has not voted" do
      @voter.voted_on?(@votable).should be false
    end

    it "should be voted as true when a voter has voted true" do
      @votable.vote :voter => @voter
      @voter.voted_as_when_voted_for(@votable).should be true
    end

    it "should be voted as false when a voter has voted false" do
      @votable.vote :voter => @voter, :vote => false
      @voter.voted_as_when_voted_for(@votable).should be false
    end

    it "should be voted as nil when a voter has never voted" do
      @voter.voted_as_when_voting_on(@votable).should be nil
    end

    it "should return true if voter has voted true" do
      @votable.vote :voter => @voter
      @voter.voted_up_on?(@votable).should be true
    end

    it "should return false if voter has not voted true" do
      @votable.vote :voter => @voter, :vote => false
      @voter.voted_up_on?(@votable).should be false
    end

    it "should return true if the voter has voted false" do
      @votable.vote :voter => @voter, :vote => false
      @voter.voted_down_on?(@votable).should be true
    end

    it "should return false if the voter has not voted false" do
      @votable.vote :voter => @voter, :vote => true
      @voter.voted_down_on?(@votable).should be false
    end

    it "should provide reserve functionality, voter can vote on votable" do
      @voter.vote :votable => @votable, :vote => 'bad'
      @voter.voted_as_when_voting_on(@votable).should be false
    end

    it "should allow the voter to vote up a model" do
      @voter.vote_up_for @votable
      @votable.up_votes.first.voter.should == @voter
      @votable.votes.up.first.voter.should == @voter
    end

    it "should allow the voter to vote down a model" do
      @voter.vote_down_for @votable
      @votable.down_votes.first.voter.should == @voter
      @votable.votes.down.first.voter.should == @voter
    end

    it "should allow the voter to unvote a model" do
      @voter.vote_up_for @votable
      @voter.unvote_for @votable
      @votable.find_votes.size.should == 0
      @votable.votes.count.should == 0
    end

    it "should get all of the voters votes" do
      @voter.vote_up_for @votable
      @voter.find_votes.size.should == 1
      @voter.votes.up.count.should == 1
    end

    it "should get all of the voters up votes" do
      @voter.vote_up_for @votable
      @voter.find_up_votes.size.should == 1
      @voter.votes.up.count.should == 1
    end

    it "should get all of the voters down votes" do
      @voter.vote_down_for @votable
      @voter.find_down_votes.size.should == 1
      @voter.votes.down.count.should == 1
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

    describe '#find_voted_items' do
      it 'returns objects that a user has upvoted for' do
        @votable.vote :voter => @voter
        @votable2.vote :voter => @voter2
        @voter.find_voted_items.should include @votable
        @voter.find_voted_items.size.should == 1
      end

      it 'returns objects that a user has downvoted for' do
        @votable.vote_down @voter
        @votable2.vote_down @voter2
        @voter.find_voted_items.should include @votable
        @voter.find_voted_items.size.should == 1
      end
    end

    describe '#find_up_voted_items' do
      it 'returns objects that a user has upvoted for' do
        @votable.vote :voter => @voter
        @votable2.vote :voter => @voter2
        @voter.find_up_voted_items.should include @votable
        @voter.find_up_voted_items.size.should == 1
      end

      it 'does not return objects that a user has downvoted for' do
        @votable.vote_down @voter
        @voter.find_up_voted_items.size.should == 0
      end
    end

    describe '#find_down_voted_items' do
      it 'does not return objects that a user has upvoted for' do
        @votable.vote :voter => @voter
        @voter.find_down_voted_items.size.should == 0
      end

      it 'returns objects that a user has downvoted for' do
        @votable.vote_down @voter
        @votable2.vote_down @voter2
        @voter.find_down_voted_items.should include @votable
        @voter.find_down_voted_items.size.should == 1
      end
    end

    describe '#get_voted' do
      subject { @voter.get_voted(@votable.class) }

      it 'returns objects of a class that a voter has voted for' do
        @votable.vote :voter => @voter
        @votable2.vote_down @voter
        subject.should include @votable
        subject.should include @votable2
        subject.size.should == 2
      end

      it 'does not return objects of a class that a voter has voted for' do
        @votable.vote :voter => @voter2
        @votable2.vote :voter => @voter2
        subject.size.should == 0
      end
    end

    describe '#get_up_voted' do
      subject { @voter.get_up_voted(@votable.class) }

      it 'returns up voted items that a voter has voted for' do
        @votable.vote :voter => @voter
        subject.should include @votable
        subject.size.should == 1
      end

      it 'does not return down voted items a voter has voted for' do
        @votable.vote_down @voter
        subject.size.should == 0
      end
    end

    describe '#get_down_voted' do
      subject { @voter.get_down_voted(@votable.class) }

      it 'does not return up voted items that a voter has voted for' do
        @votable.vote :voter => @voter
        subject.size.should == 0
      end

      it 'returns down voted items a voter has voted for' do
        @votable.vote_down @voter
        subject.should include @votable
        subject.size.should == 1
      end
    end
  end
end
