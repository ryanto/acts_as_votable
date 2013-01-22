require 'acts_as_votable'
require 'spec_helper'

describe ActsAsVotable::Votable do

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

    it "should return false when a vote with no voter is saved" do
      @votable.vote.should be false
    end

    it "should have one vote when saved" do
      @votable.vote :voter => @voter, :vote => 'yes'
      @votable.votes.size.should == 1
    end

    it "should have one vote when voted on twice by the same person" do
      @votable.vote :voter => @voter, :vote => 'yes'
      @votable.vote :voter => @voter, :vote => 'no'
      @votable.votes.size.should == 1
    end

    it "should have one scoped vote when voting under an scope" do
      @votable.vote :voter => @voter, :vote => 'yes', :vote_scope => 'rank'
      @votable.find_votes(:vote_scope => 'rank').size.should == 1
    end

    it "should have one vote when voted on twice using scope by the same person" do
      @votable.vote :voter => @voter, :vote => 'yes', :vote_scope => 'rank'
      @votable.vote :voter => @voter, :vote => 'no', :vote_scope => 'rank'
      @votable.find_votes(:vote_scope => 'rank').size.should == 1
    end

    it "should have two votes when voting on two different scopes by the same person" do
      @votable.vote :voter => @voter, :vote => 'yes', :vote_scope => 'weekly_rank'
      @votable.vote :voter => @voter, :vote => 'no', :vote_scope => 'monthly_rank'
      @votable.votes.size.should == 2
    end

    it "should be callable with vote_up" do
      @votable.vote_up @voter
      @votable.up_votes.first.voter.should == @voter
    end

    it "should be callable with vote_down" do
      @votable.vote_down @voter
      @votable.down_votes.first.voter.should == @voter
    end

    it "should have 2 votes when voted on once by two different people" do
      @votable.vote :voter => @voter
      @votable.vote :voter => @voter2
      @votable.votes.size.should == 2
    end

    it "should have one true vote" do
      @votable.vote :voter => @voter
      @votable.vote :voter => @voter2, :vote => 'dislike'
      @votable.up_votes.size.should == 1
    end

    it "should have 2 false votes" do
      @votable.vote :voter => @voter, :vote => 'no'
      @votable.vote :voter => @voter2, :vote => 'dislike'
      @votable.down_votes.size.should == 2
    end

    it "should have been voted on by voter2" do
      @votable.vote :voter => @voter2, :vote => true
      @votable.find_votes.first.voter.id.should be @voter2.id
    end

    it "should count the vote as registered if this is the voters first vote" do
      @votable.vote :voter => @voter
      @votable.vote_registered?.should be true
    end

    it "should not count the vote as being registered if that voter has already voted and the vote has not changed" do
      @votable.vote :voter => @voter, :vote => true
      @votable.vote :voter => @voter, :vote => 'yes'
      @votable.vote_registered?.should be false
    end

    it "should count the vote as registered if the voter has voted and the vote has changed" do
      @votable.vote :voter => @voter, :vote => true
      @votable.vote :voter => @voter, :vote => 'dislike'
      @votable.vote_registered?.should be true
    end

    it "should be voted on by voter" do
      @votable.vote :voter => @voter
      @votable.voted_on_by?(@voter).should be true
    end

    it "should unvote a positive vote" do
      @votable.vote :voter => @voter
      @votable.unvote :voter => @voter
      @votable.find_votes.count.should == 0
    end

    it "should set the votable to unregistered after unvoting" do
      @votable.vote :voter => @voter
      @votable.unvote :voter => @voter
      @votable.vote_registered?.should be false
    end

    it "should unvote a negative vote" do
      @votable.vote :voter => @voter, :vote => 'no'
      @votable.unvote :voter => @voter
      @votable.find_votes.count.should == 0
    end

    it "should unvote only the from a single voter" do
      @votable.vote :voter => @voter
      @votable.vote :voter => @voter2
      @votable.unvote :voter => @voter
      @votable.find_votes.count.should == 1
    end

    it "should be contained to instances" do
      votable2 = Votable.new(:name => '2nd votable')
      votable2.save

      @votable.vote :voter => @voter, :vote => false
      votable2.vote :voter => @voter, :vote => true
      votable2.vote :voter => @voter, :vote => true

      @votable.vote_registered?.should be true
      votable2.vote_registered?.should be false
    end

    describe "with cached votes" do

      before(:each) do
        clean_database
        @voter = Voter.new(:name => 'i can vote!')
        @voter.save

        @votable = Votable.new(:name => 'a voting model without a cache')
        @votable.save

        @votable_cache = VotableCache.new(:name => 'voting model with cache')
        @votable_cache.save
      end

      it "should not update cached votes if there are no columns" do
        @votable.vote :voter => @voter
      end

      it "should update cached total votes if there is a total column" do
        @votable_cache.cached_votes_total = 50
        @votable_cache.vote :voter => @voter
        @votable_cache.cached_votes_total.should == 1
      end

      it "should update cached total votes when a vote up is removed" do
        @votable_cache.vote :voter => @voter, :vote => 'true'
        @votable_cache.unvote :voter => @voter
        @votable_cache.cached_votes_total.should == 0
      end

      it "should update cached total votes when a vote down is removed" do
        @votable_cache.vote :voter => @voter, :vote => 'false'
        @votable_cache.unvote :voter => @voter
        @votable_cache.cached_votes_total.should == 0
      end

      it "should update cached score votes if there is a score column" do
        @votable_cache.cached_votes_score = 50
        @votable_cache.vote :voter => @voter
        @votable_cache.cached_votes_score.should == 1
        @votable_cache.vote :voter => @voter2, :vote => 'false'
        @votable_cache.cached_votes_score.should == 0
        @votable_cache.vote :voter => @voter, :vote => 'false'
        @votable_cache.cached_votes_score.should == -2
      end

      it "should update cached score votes when a vote up is removed" do
        @votable_cache.vote :voter => @voter, :vote => 'true'
        @votable_cache.cached_votes_score.should == 1
        @votable_cache.unvote :voter => @voter
        @votable_cache.cached_votes_score.should == 0
      end

      it "should update cached score votes when a vote down is removed" do
        @votable_cache.vote :voter => @voter, :vote => 'false'
        @votable_cache.cached_votes_score.should == -1
        @votable_cache.unvote :voter => @voter
        @votable_cache.cached_votes_score.should == 0
      end

      it "should update cached up votes if there is an up vote column" do
        @votable_cache.cached_votes_up = 50
        @votable_cache.vote :voter => @voter
        @votable_cache.vote :voter => @voter
        @votable_cache.cached_votes_up.should == 1
      end

      it "should update cached down votes if there is a down vote column" do
        @votable_cache.cached_votes_down = 50
        @votable_cache.vote :voter => @voter, :vote => 'false'
        @votable_cache.cached_votes_down.should == 1
      end

      it "should update cached up votes when a vote up is removed" do
        @votable_cache.vote :voter => @voter, :vote => 'true'
        @votable_cache.unvote :voter => @voter
        @votable_cache.cached_votes_up.should == 0
      end

      it "should update cached down votes when a vote down is removed" do
        @votable_cache.vote :voter => @voter, :vote => 'false'
        @votable_cache.unvote :voter => @voter
        @votable_cache.cached_votes_down.should == 0
      end

      it "should select from cached total votes if there a total column" do
        @votable_cache.vote :voter => @voter
        @votable_cache.cached_votes_total = 50
        @votable_cache.count_votes_total.should == 50
      end

      it "should select from cached up votes if there is an up vote column" do
        @votable_cache.vote :voter => @voter
        @votable_cache.cached_votes_up = 50
        @votable_cache.count_votes_up.should == 50
      end

      it "should select from cached down votes if there is a down vote column" do
        @votable_cache.vote :voter => @voter, :vote => 'false'
        @votable_cache.cached_votes_down = 50
        @votable_cache.count_votes_down.should == 50
      end

    end

    describe "sti models" do

      before(:each) do
        clean_database
        @voter = Voter.create(:name => 'i can vote!')
      end

      it "should be able to vote on a votable child of a non votable sti model" do
        votable = VotableChildOfStiNotVotable.create(:name => 'sti child')

        votable.vote :voter => @voter, :vote => 'yes'
        votable.votes.size.should == 1
      end

      it "should not be able to vote on a parent non votable" do
        StiNotVotable.should_not be_votable
      end

      it "should be able to vote on a child when its parent is votable" do
        votable = ChildOfStiVotable.create(:name => 'sti child')

        votable.vote :voter => @voter, :vote => 'yes'
        votable.votes.size.should == 1
      end

    end

  end


end
