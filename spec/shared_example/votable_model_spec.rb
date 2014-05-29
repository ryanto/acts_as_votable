shared_examples "a votable_model" do
  it "should return false when a vote with no voter is saved" do
    votable.vote_by.should be false
  end

  it "should have one vote when saved" do
    votable.vote_by :voter => voter, :vote => 'yes'
    votable.votes_for.size.should == 1
  end

  it "should have one vote when voted on twice by the same person" do
    votable.vote_by :voter => voter, :vote => 'yes'
    votable.vote_by :voter => voter, :vote => 'no'
    votable.votes_for.size.should == 1
  end

  it "should have two votes_for when voted on twice by the same person with duplicate paramenter" do
    votable.vote_by :voter => voter, :vote => 'yes'
    votable.vote_by :voter => voter, :vote => 'no', :duplicate => true
    votable.votes_for.size.should == 2
  end

  it "should have one scoped vote when voting under an scope" do
    votable.vote_by :voter => voter, :vote => 'yes', :vote_scope => 'rank'
    votable.find_votes_for(:vote_scope => 'rank').size.should == 1
  end

  it "should have one vote when voted on twice using scope by the same person" do
    votable.vote_by :voter => voter, :vote => 'yes', :vote_scope => 'rank'
    votable.vote_by :voter => voter, :vote => 'no', :vote_scope => 'rank'
    votable.find_votes_for(:vote_scope => 'rank').size.should == 1
  end

  it "should have two votes_for when voting on two different scopes by the same person" do
    votable.vote_by :voter => voter, :vote => 'yes', :vote_scope => 'weekly_rank'
    votable.vote_by :voter => voter, :vote => 'no', :vote_scope => 'monthly_rank'
    votable.votes_for.size.should == 2
  end

  it "should be callable with vote_up" do
    votable.vote_up voter
    votable.get_up_votes.first.voter.should == voter
  end

  it "should be callable with vote_down" do
    votable.vote_down voter
    votable.get_down_votes.first.voter.should == voter
  end

  it "should have 2 votes_for when voted on once by two different people" do
    votable.vote_by :voter => voter
    votable.vote_by :voter => voter2
    votable.votes_for.size.should == 2
  end

  it "should have one true vote" do
    votable.vote_by :voter => voter
    votable.vote_by :voter => voter2, :vote => 'dislike'
    votable.get_up_votes.size.should == 1
  end

  it "should have 2 false votes_for" do
    votable.vote_by :voter => voter, :vote => 'no'
    votable.vote_by :voter => voter2, :vote => 'dislike'
    votable.get_down_votes.size.should == 2
  end

  it "should have been voted on by voter2" do
    votable.vote_by :voter => voter2, :vote => true
    votable.find_votes_for.first.voter.id.should be voter2.id
  end

  it "should count the vote as registered if this is the voters first vote" do
    votable.vote_by :voter => voter
    votable.vote_registered?.should be true
  end

  it "should not count the vote as being registered if that voter has already voted and the vote has not changed" do
    votable.vote_by :voter => voter, :vote => true
    votable.vote_by :voter => voter, :vote => 'yes'
    votable.vote_registered?.should be false
  end

  it "should count the vote as registered if the voter has voted and the vote flag has changed" do
    votable.vote_by :voter => voter, :vote => true
    votable.vote_by :voter => voter, :vote => 'dislike'
    votable.vote_registered?.should be true
  end

  it "should count the vote as registered if the voter has voted and the vote weight has changed" do
    votable.vote_by :voter => voter, :vote => true, :vote_weight => 1
    votable.vote_by :voter => voter, :vote => true, :vote_weight => 2
    votable.vote_registered?.should be true
  end

  it "should be voted on by voter" do
    votable.vote_by :voter => voter
    votable.voted_on_by?(voter).should be true
  end

  it "should be able to unvote a voter" do
    votable.liked_by(voter)
    votable.unliked_by(voter)
    votable.voted_on_by?(voter).should be false
  end

  it "should unvote a positive vote" do
    votable.vote_by :voter => voter
    votable.unvote :voter => voter
    votable.find_votes_for.count.should == 0
  end

  it "should set the votable to unregistered after unvoting" do
    votable.vote_by :voter => voter
    votable.unvote :voter => voter
    votable.vote_registered?.should be false
  end

  it "should unvote a negative vote" do
    votable.vote_by :voter => voter, :vote => 'no'
    votable.unvote :voter => voter
    votable.find_votes_for.count.should == 0
  end

  it "should unvote only the from a single voter" do
    votable.vote_by :voter => voter
    votable.vote_by :voter => voter2
    votable.unvote :voter => voter
    votable.find_votes_for.count.should == 1
  end

  it "should be contained to instances" do
    votable2 = Votable.new(:name => '2nd votable')
    votable2.save

    votable.vote_by :voter => voter, :vote => false
    votable2.vote_by :voter => voter, :vote => true
    votable2.vote_by :voter => voter, :vote => true

    votable.vote_registered?.should be true
    votable2.vote_registered?.should be false
  end

  it "should set default vote weight to 1 if not specified" do
    votable.upvote_by voter
    votable.find_votes_for.first.vote_weight.should == 1
  end

  describe "with cached votes_for" do

    before(:each) do
      clean_database
      voter = Voter.new(:name => 'i can vote!')
      voter.save

      votable = Votable.new(:name => 'a voting model without a cache')
      votable.save

      votable_cache = VotableCache.new(:name => 'voting model with cache')
      votable_cache.save
    end

    it "should not update cached votes_for if there are no columns" do
      votable.vote_by :voter => voter
    end

    it "should update cached total votes_for if there is a total column" do
      votable_cache.cached_votes_total = 50
      votable_cache.vote_by :voter => voter
      votable_cache.cached_votes_total.should == 1
    end

    it "should update cached total votes_for when a vote up is removed" do
      votable_cache.vote_by :voter => voter, :vote => 'true'
      votable_cache.unvote :voter => voter
      votable_cache.cached_votes_total.should == 0
    end

    it "should update cached total votes_for when a vote down is removed" do
      votable_cache.vote_by :voter => voter, :vote => 'false'
      votable_cache.unvote :voter => voter
      votable_cache.cached_votes_total.should == 0
    end

    it "should update cached score votes_for if there is a score column" do
      votable_cache.cached_votes_score = 50
      votable_cache.vote_by :voter => voter
      votable_cache.cached_votes_score.should == 1
      votable_cache.vote_by :voter => voter2, :vote => 'false'
      votable_cache.cached_votes_score.should == 0
      votable_cache.vote_by :voter => voter, :vote => 'false'
      votable_cache.cached_votes_score.should == -2
    end

    it "should update cached score votes_for when a vote up is removed" do
      votable_cache.vote_by :voter => voter, :vote => 'true'
      votable_cache.cached_votes_score.should == 1
      votable_cache.unvote :voter => voter
      votable_cache.cached_votes_score.should == 0
    end

    it "should update cached score votes_for when a vote down is removed" do
      votable_cache.vote_by :voter => voter, :vote => 'false'
      votable_cache.cached_votes_score.should == -1
      votable_cache.unvote :voter => voter
      votable_cache.cached_votes_score.should == 0
    end

    it "should update cached weighted total if there is a weighted total column" do
      votable_cache.cached_weighted_total = 50
      votable_cache.vote_by :voter => voter
      votable_cache.cached_weighted_total.should == 1
      votable_cache.vote_by :voter => voter2, :vote => 'false'
      votable_cache.cached_weighted_total.should == 2
    end

    it "should update cached weighted total votes_for when a vote up is removed" do
      votable_cache.vote_by :voter => voter, :vote => 'true', :vote_weight => 3
      votable_cache.cached_weighted_total.should == 3
      votable_cache.unvote :voter => voter
      votable_cache.cached_weighted_total.should == 0
    end

    it "should update cached weighted total votes_for when a vote down is removed" do
      votable_cache.vote_by :voter => voter, :vote => 'false', :vote_weight => 4
      votable_cache.cached_weighted_total.should == 4
      votable_cache.unvote :voter => voter
      votable_cache.cached_weighted_total.should == 0
    end

    it "should update cached weighted score if there is a weighted score column" do
      votable_cache.cached_weighted_score = 50
      votable_cache.vote_by :voter => voter
      votable_cache.cached_weighted_score.should == 1
      votable_cache.vote_by :voter => voter2, :vote => 'false'
      votable_cache.cached_weighted_score.should == 0
      votable_cache.vote_by :voter => voter, :vote => 'false'
      votable_cache.cached_weighted_score.should == -2
    end

    it "should update cached weighted score votes_for when a vote up is removed" do
      votable_cache.vote_by :voter => voter, :vote => 'true', :vote_weight => 3
      votable_cache.cached_weighted_score.should == 3
      votable_cache.unvote :voter => voter
      votable_cache.cached_weighted_score.should == 0
    end

    it "should update cached weighted score votes_for when a vote down is removed" do
      votable_cache.vote_by :voter => voter, :vote => 'false', :vote_weight => 4
      votable_cache.cached_weighted_score.should == -4
      votable_cache.unvote :voter => voter
      votable_cache.cached_weighted_score.should == 0
    end

    it "should update cached up votes_for if there is an up vote column" do
      votable_cache.cached_votes_up = 50
      votable_cache.vote_by :voter => voter
      votable_cache.vote_by :voter => voter
      votable_cache.cached_votes_up.should == 1
    end

    it "should update cached down votes_for if there is a down vote column" do
      votable_cache.cached_votes_down = 50
      votable_cache.vote_by :voter => voter, :vote => 'false'
      votable_cache.cached_votes_down.should == 1
    end

    it "should update cached up votes_for when a vote up is removed" do
      votable_cache.vote_by :voter => voter, :vote => 'true'
      votable_cache.unvote :voter => voter
      votable_cache.cached_votes_up.should == 0
    end

    it "should update cached down votes_for when a vote down is removed" do
      votable_cache.vote_by :voter => voter, :vote => 'false'
      votable_cache.unvote :voter => voter
      votable_cache.cached_votes_down.should == 0
    end

    it "should select from cached total votes_for if there a total column" do
      votable_cache.vote_by :voter => voter
      votable_cache.cached_votes_total = 50
      votable_cache.count_votes_total.should == 50
    end

    it "should select from cached up votes_for if there is an up vote column" do
      votable_cache.vote_by :voter => voter
      votable_cache.cached_votes_up = 50
      votable_cache.count_votes_up.should == 50
    end

    it "should select from cached down votes_for if there is a down vote column" do
      votable_cache.vote_by :voter => voter, :vote => 'false'
      votable_cache.cached_votes_down = 50
      votable_cache.count_votes_down.should == 50
    end

    it "should select from cached weighted total if there is a weighted total column" do
      votable_cache.vote_by :voter => voter, :vote => 'false'
      votable_cache.cached_weighted_total = 50
      votable_cache.weighted_total.should == 50
    end

    it "should select from cached weighted score if there is a weighted score column" do
      votable_cache.vote_by :voter => voter, :vote => 'false'
      votable_cache.cached_weighted_score = 50
      votable_cache.weighted_score.should == 50
    end

  end

  describe "with scoped cached votes_for" do
    
    it "should update cached total votes_for if there is a total column" do
      votable_cache.cached_scoped_test_votes_total = 50
      votable_cache.vote_by :voter => voter, :vote_scope => "test"
      votable_cache.cached_scoped_test_votes_total.should == 1
    end

    it "should update cached total votes_for when a vote up is removed" do
      votable_cache.vote_by :voter => voter, :vote => 'true', :vote_scope => "test"
      votable_cache.unvote :voter => voter, :vote_scope => "test"
      votable_cache.cached_scoped_test_votes_total.should == 0
    end

    it "should update cached total votes_for when a vote down is removed" do
      votable_cache.vote_by :voter => voter, :vote => 'false', :vote_scope => "test"
      votable_cache.unvote :voter => voter, :vote_scope => "test"
      votable_cache.cached_scoped_test_votes_total.should == 0
    end

    it "should update cached score votes_for if there is a score column" do
      votable_cache.cached_scoped_test_votes_score = 50
      votable_cache.vote_by :voter => voter, :vote_scope => "test"
      votable_cache.cached_scoped_test_votes_score.should == 1
      votable_cache.vote_by :voter => voter2, :vote => 'false', :vote_scope => "test"
      votable_cache.cached_scoped_test_votes_score.should == 0
      votable_cache.vote_by :voter => voter, :vote => 'false', :vote_scope => "test"
      votable_cache.cached_scoped_test_votes_score.should == -2
    end

    it "should update cached score votes_for when a vote up is removed" do
      votable_cache.vote_by :voter => voter, :vote => 'true', :vote_scope => "test"
      votable_cache.cached_scoped_test_votes_score.should == 1
      votable_cache.unvote :voter => voter, :vote_scope => "test"
      votable_cache.cached_scoped_test_votes_score.should == 0
    end

    it "should update cached score votes_for when a vote down is removed" do
      votable_cache.vote_by :voter => voter, :vote => 'false', :vote_scope => "test"
      votable_cache.cached_scoped_test_votes_score.should == -1
      votable_cache.unvote :voter => voter, :vote_scope => "test"
      votable_cache.cached_scoped_test_votes_score.should == 0
    end

    it "should update cached up votes_for if there is an up vote column" do
      votable_cache.cached_scoped_test_votes_up = 50
      votable_cache.vote_by :voter => voter, :vote_scope => "test"
      votable_cache.vote_by :voter => voter, :vote_scope => "test"
      votable_cache.cached_scoped_test_votes_up.should == 1
    end

    it "should update cached down votes_for if there is a down vote column" do
      votable_cache.cached_scoped_test_votes_down = 50
      votable_cache.vote_by :voter => voter, :vote => 'false', :vote_scope => "test"
      votable_cache.cached_scoped_test_votes_down.should == 1
    end

    it "should update cached up votes_for when a vote up is removed" do
      votable_cache.vote_by :voter => voter, :vote => 'true', :vote_scope => "test"
      votable_cache.unvote :voter => voter, :vote_scope => "test"
      votable_cache.cached_scoped_test_votes_up.should == 0
    end

    it "should update cached down votes_for when a vote down is removed" do
      votable_cache.vote_by :voter => voter, :vote => 'false', :vote_scope => "test"
      votable_cache.unvote :voter => voter, :vote_scope => "test"
      votable_cache.cached_scoped_test_votes_down.should == 0
    end

    it "should select from cached total votes_for if there a total column" do
      votable_cache.vote_by :voter => voter, :vote_scope => "test"
      votable_cache.cached_scoped_test_votes_total = 50
      votable_cache.count_votes_total(false, "test").should == 50
    end

    it "should select from cached up votes_for if there is an up vote column" do
      votable_cache.vote_by :voter => voter, :vote_scope => "test"
      votable_cache.cached_scoped_test_votes_up = 50
      votable_cache.count_votes_up(false, "test").should == 50
    end

    it "should select from cached down votes_for if there is a down vote column" do
      votable_cache.vote_by :voter => voter, :vote => 'false', :vote_scope => "test"
      votable_cache.cached_scoped_test_votes_down = 50
      votable_cache.count_votes_down(false, "test").should == 50
    end

  end

  describe "sti models" do

    it "should be able to vote on a votable child of a non votable sti model" do
      votable = VotableChildOfStiNotVotable.create(:name => 'sti child')

      votable.vote_by :voter => voter, :vote => 'yes'
      votable.votes_for.size.should == 1
    end

    it "should not be able to vote on a parent non votable" do
      StiNotVotable.should_not be_votable
    end

    it "should be able to vote on a child when its parent is votable" do
      votable = ChildOfStiVotable.create(:name => 'sti child')

      votable.vote_by :voter => voter, :vote => 'yes'
      votable.votes_for.size.should == 1
    end
  end
end
