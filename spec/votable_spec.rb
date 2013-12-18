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
      @votable.voted_by.size.should == 1
    end

    it "should have one vote when voted on twice by the same person" do
      @votable.vote :voter => @voter, :vote => 'yes'
      @votable.vote :voter => @voter, :vote => 'no'
      @votable.voted_by.size.should == 1
    end

    it "should have two voted_by when voted on twice by the same person with duplicate paramenter" do
      @votable.vote :voter => @voter, :vote => 'yes'
      @votable.vote :voter => @voter, :vote => 'no', :duplicate => true
      @votable.voted_by.size.should == 2
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

    it "should have two voted_by when voting on two different scopes by the same person" do
      @votable.vote :voter => @voter, :vote => 'yes', :vote_scope => 'weekly_rank'
      @votable.vote :voter => @voter, :vote => 'no', :vote_scope => 'monthly_rank'
      @votable.voted_by.size.should == 2
    end

    it "should be callable with vote_up" do
      @votable.vote_up @voter
      @votable.up_votes.first.voter.should == @voter
    end

    it "should be callable with vote_down" do
      @votable.vote_down @voter
      @votable.down_votes.first.voter.should == @voter
    end

    it "should have 2 voted_by when voted on once by two different people" do
      @votable.vote :voter => @voter
      @votable.vote :voter => @voter2
      @votable.voted_by.size.should == 2
    end

    it "should have one true vote" do
      @votable.vote :voter => @voter
      @votable.vote :voter => @voter2, :vote => 'dislike'
      @votable.up_votes.size.should == 1
    end

    it "should have 2 false voted_by" do
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

    it "should be able to unvote a voter" do
      @votable.liked_by(@voter)
      @votable.unliked_by(@voter)
      @votable.voted_on_by?(@voter).should be false
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

    it "should set default vote weight to 1 if not specified" do
      @votable.upvote_by @voter
      @votable.find_votes.first.vote_weight.should == 1
    end

    describe "with cached voted_by" do

      before(:each) do
        clean_database
        @voter = Voter.new(:name => 'i can vote!')
        @voter.save

        @votable = Votable.new(:name => 'a voting model without a cache')
        @votable.save

        @votable_cache = VotableCache.new(:name => 'voting model with cache')
        @votable_cache.save
      end

      it "should not update cached voted_by if there are no columns" do
        @votable.vote :voter => @voter
      end

      it "should update cached total voted_by if there is a total column" do
        @votable_cache.cached_votes_total = 50
        @votable_cache.vote :voter => @voter
        @votable_cache.cached_votes_total.should == 1
      end

      it "should update cached total voted_by when a vote up is removed" do
        @votable_cache.vote :voter => @voter, :vote => 'true'
        @votable_cache.unvote :voter => @voter
        @votable_cache.cached_votes_total.should == 0
      end

      it "should update cached total voted_by when a vote down is removed" do
        @votable_cache.vote :voter => @voter, :vote => 'false'
        @votable_cache.unvote :voter => @voter
        @votable_cache.cached_votes_total.should == 0
      end

      it "should update cached score voted_by if there is a score column" do
        @votable_cache.cached_votes_score = 50
        @votable_cache.vote :voter => @voter
        @votable_cache.cached_votes_score.should == 1
        @votable_cache.vote :voter => @voter2, :vote => 'false'
        @votable_cache.cached_votes_score.should == 0
        @votable_cache.vote :voter => @voter, :vote => 'false'
        @votable_cache.cached_votes_score.should == -2
      end

      it "should update cached score voted_by when a vote up is removed" do
        @votable_cache.vote :voter => @voter, :vote => 'true'
        @votable_cache.cached_votes_score.should == 1
        @votable_cache.unvote :voter => @voter
        @votable_cache.cached_votes_score.should == 0
      end

      it "should update cached score voted_by when a vote down is removed" do
        @votable_cache.vote :voter => @voter, :vote => 'false'
        @votable_cache.cached_votes_score.should == -1
        @votable_cache.unvote :voter => @voter
        @votable_cache.cached_votes_score.should == 0
      end

      it "should update cached weighted score if there is a weighted score column" do
        @votable_cache.cached_weighted_score = 50
        @votable_cache.vote :voter => @voter
        @votable_cache.cached_weighted_score.should == 1
        @votable_cache.vote :voter => @voter2, :vote => 'false'
        @votable_cache.cached_weighted_score.should == 0
        @votable_cache.vote :voter => @voter, :vote => 'false'
        @votable_cache.cached_weighted_score.should == -2
      end

      it "should update cached weighted score voted_by when a vote up is removed" do
        @votable_cache.vote :voter => @voter, :vote => 'true', :vote_weight => 3
        @votable_cache.cached_weighted_score.should == 3
        @votable_cache.unvote :voter => @voter
        @votable_cache.cached_weighted_score.should == 0
      end

      it "should update cached weighted score voted_by when a vote down is removed" do
        @votable_cache.vote :voter => @voter, :vote => 'false', :vote_weight => 4
        @votable_cache.cached_weighted_score.should == -4
        @votable_cache.unvote :voter => @voter
        @votable_cache.cached_weighted_score.should == 0
      end

      it "should update cached up voted_by if there is an up vote column" do
        @votable_cache.cached_votes_up = 50
        @votable_cache.vote :voter => @voter
        @votable_cache.vote :voter => @voter
        @votable_cache.cached_votes_up.should == 1
      end

      it "should update cached down voted_by if there is a down vote column" do
        @votable_cache.cached_votes_down = 50
        @votable_cache.vote :voter => @voter, :vote => 'false'
        @votable_cache.cached_votes_down.should == 1
      end

      it "should update cached up voted_by when a vote up is removed" do
        @votable_cache.vote :voter => @voter, :vote => 'true'
        @votable_cache.unvote :voter => @voter
        @votable_cache.cached_votes_up.should == 0
      end

      it "should update cached down voted_by when a vote down is removed" do
        @votable_cache.vote :voter => @voter, :vote => 'false'
        @votable_cache.unvote :voter => @voter
        @votable_cache.cached_votes_down.should == 0
      end

      it "should select from cached total voted_by if there a total column" do
        @votable_cache.vote :voter => @voter
        @votable_cache.cached_votes_total = 50
        @votable_cache.count_votes_total.should == 50
      end

      it "should select from cached up voted_by if there is an up vote column" do
        @votable_cache.vote :voter => @voter
        @votable_cache.cached_votes_up = 50
        @votable_cache.count_votes_up.should == 50
      end

      it "should select from cached down voted_by if there is a down vote column" do
        @votable_cache.vote :voter => @voter, :vote => 'false'
        @votable_cache.cached_votes_down = 50
        @votable_cache.count_votes_down.should == 50
      end

      it "should select from cached weighted score if there is a weighted score column" do
        @votable_cache.vote :voter => @voter, :vote => 'false'
        @votable_cache.cached_weighted_score = 50
        @votable_cache.weighted_score.should == 50
      end

    end

    describe "with scoped cached voted_by" do

      before(:each) do
        clean_database
        @voter = Voter.new(:name => 'i can vote!')
        @voter.save

        @votable = Votable.new(:name => 'a voting model without a cache')
        @votable.save

        @votable_cache = VotableCache.new(:name => 'voting model with cache')
        @votable_cache.save
      end

      it "should update cached total voted_by if there is a total column" do
        @votable_cache.cached_scoped_test_votes_total = 50
        @votable_cache.vote :voter => @voter, :vote_scope => "test"
        @votable_cache.cached_scoped_test_votes_total.should == 1
      end

      it "should update cached total voted_by when a vote up is removed" do
        @votable_cache.vote :voter => @voter, :vote => 'true', :vote_scope => "test"
        @votable_cache.unvote :voter => @voter, :vote_scope => "test"
        @votable_cache.cached_scoped_test_votes_total.should == 0
      end

      it "should update cached total voted_by when a vote down is removed" do
        @votable_cache.vote :voter => @voter, :vote => 'false', :vote_scope => "test"
        @votable_cache.unvote :voter => @voter, :vote_scope => "test"
        @votable_cache.cached_scoped_test_votes_total.should == 0
      end

      it "should update cached score voted_by if there is a score column" do
        @votable_cache.cached_scoped_test_votes_score = 50
        @votable_cache.vote :voter => @voter, :vote_scope => "test"
        @votable_cache.cached_scoped_test_votes_score.should == 1
        @votable_cache.vote :voter => @voter2, :vote => 'false', :vote_scope => "test"
        @votable_cache.cached_scoped_test_votes_score.should == 0
        @votable_cache.vote :voter => @voter, :vote => 'false', :vote_scope => "test"
        @votable_cache.cached_scoped_test_votes_score.should == -2
      end

      it "should update cached score voted_by when a vote up is removed" do
        @votable_cache.vote :voter => @voter, :vote => 'true', :vote_scope => "test"
        @votable_cache.cached_scoped_test_votes_score.should == 1
        @votable_cache.unvote :voter => @voter, :vote_scope => "test"
        @votable_cache.cached_scoped_test_votes_score.should == 0
      end

      it "should update cached score voted_by when a vote down is removed" do
        @votable_cache.vote :voter => @voter, :vote => 'false', :vote_scope => "test"
        @votable_cache.cached_scoped_test_votes_score.should == -1
        @votable_cache.unvote :voter => @voter, :vote_scope => "test"
        @votable_cache.cached_scoped_test_votes_score.should == 0
      end

      it "should update cached up voted_by if there is an up vote column" do
        @votable_cache.cached_scoped_test_votes_up = 50
        @votable_cache.vote :voter => @voter, :vote_scope => "test"
        @votable_cache.vote :voter => @voter, :vote_scope => "test"
        @votable_cache.cached_scoped_test_votes_up.should == 1
      end

      it "should update cached down voted_by if there is a down vote column" do
        @votable_cache.cached_scoped_test_votes_down = 50
        @votable_cache.vote :voter => @voter, :vote => 'false', :vote_scope => "test"
        @votable_cache.cached_scoped_test_votes_down.should == 1
      end

      it "should update cached up voted_by when a vote up is removed" do
        @votable_cache.vote :voter => @voter, :vote => 'true', :vote_scope => "test"
        @votable_cache.unvote :voter => @voter, :vote_scope => "test"
        @votable_cache.cached_scoped_test_votes_up.should == 0
      end

      it "should update cached down voted_by when a vote down is removed" do
        @votable_cache.vote :voter => @voter, :vote => 'false', :vote_scope => "test"
        @votable_cache.unvote :voter => @voter, :vote_scope => "test"
        @votable_cache.cached_scoped_test_votes_down.should == 0
      end

      it "should select from cached total voted_by if there a total column" do
        @votable_cache.vote :voter => @voter, :vote_scope => "test"
        @votable_cache.cached_scoped_test_votes_total = 50
        @votable_cache.count_votes_total(false, "test").should == 50
      end

      it "should select from cached up voted_by if there is an up vote column" do
        @votable_cache.vote :voter => @voter, :vote_scope => "test"
        @votable_cache.cached_scoped_test_votes_up = 50
        @votable_cache.count_votes_up(false, "test").should == 50
      end

      it "should select from cached down voted_by if there is a down vote column" do
        @votable_cache.vote :voter => @voter, :vote => 'false', :vote_scope => "test"
        @votable_cache.cached_scoped_test_votes_down = 50
        @votable_cache.count_votes_down(false, "test").should == 50
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
        votable.voted_by.size.should == 1
      end

      it "should not be able to vote on a parent non votable" do
        StiNotVotable.should_not be_votable
      end

      it "should be able to vote on a child when its parent is votable" do
        votable = ChildOfStiVotable.create(:name => 'sti child')

        votable.vote :voter => @voter, :vote => 'yes'
        votable.voted_by.size.should == 1
      end

    end

  end


end
