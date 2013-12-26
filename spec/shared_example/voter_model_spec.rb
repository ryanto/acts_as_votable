shared_examples "a voter_model" do
  let (:votable_klass) { votable.class }

  it "should be voted on after a voter has voted" do
    votable.vote_by :voter => voter
    voter.voted_on?(votable).should be true
    voter.voted_for?(votable).should be true
  end

  it "should not be voted on if a voter has not voted" do
    voter.voted_on?(votable).should be false
  end

  it "should be voted on after a voter has voted under scope" do
    votable.vote_by :voter => voter, :vote_scope => 'rank'
    voter.voted_on?(votable, :vote_scope => 'rank').should be true
  end

  it "should not be voted on other scope after a voter has voted under one scope" do
    votable.vote_by :voter => voter, :vote_scope => 'rank'
    voter.voted_on?(votable).should be false
  end

  it "should be voted as true when a voter has voted true" do
    votable.vote_by :voter => voter
    voter.voted_as_when_voted_on(votable).should be true
    voter.voted_as_when_voted_for(votable).should be true
  end

  it "should be voted as true when a voter has voted true under scope" do
    votable.vote_by :voter => voter, :vote_scope => 'rank'
    voter.voted_as_when_voted_for(votable, :vote_scope => 'rank').should be true
  end

  it "should be voted as false when a voter has voted false" do
    votable.vote_by :voter => voter, :vote => false
    voter.voted_as_when_voted_for(votable).should be false
  end

  it "should be voted as false when a voter has voted false under scope" do
    votable.vote_by :voter => voter, :vote => false, :vote_scope => 'rank'
    voter.voted_as_when_voted_for(votable, :vote_scope => 'rank').should be false
  end

  it "should be voted as nil when a voter has never voted" do
    voter.voted_as_when_voting_on(votable).should be nil
  end

  it "should be voted as nil when a voter has never voted under the scope" do
    votable.vote_by :voter => voter, :vote => false, :vote_scope => 'rank'
    voter.voted_as_when_voting_on(votable).should be nil
  end

  it "should return true if voter has voted true" do
    votable.vote_by :voter => voter
    voter.voted_up_on?(votable).should be true
  end

  it "should return false if voter has not voted true" do
    votable.vote_by :voter => voter, :vote => false
    voter.voted_up_on?(votable).should be false
  end

  it "should return true if the voter has voted false" do
    votable.vote_by :voter => voter, :vote => false
    voter.voted_down_on?(votable).should be true
  end

  it "should return false if the voter has not voted false" do
    votable.vote_by :voter => voter, :vote => true
    voter.voted_down_on?(votable).should be false
  end

  it "should provide reserve functionality, voter can vote on votable" do
    voter.vote :votable => votable, :vote => 'bad'
    voter.voted_as_when_voting_on(votable).should be false
  end

  it "should allow the voter to vote up a model" do
    voter.vote_up_for votable
    votable.get_up_votes.first.voter.should == voter
    votable.votes_for.up.first.voter.should == voter
  end

  it "should allow the voter to vote down a model" do
    voter.vote_down_for votable
    votable.get_down_votes.first.voter.should == voter
    votable.votes_for.down.first.voter.should == voter
  end

  it "should allow the voter to unvote a model" do
    voter.vote_up_for votable
    voter.unvote_for votable
    votable.find_votes_for.size.should == 0
    votable.votes_for.count.should == 0
  end

  it "should get all of the voters votes" do
    voter.vote_up_for votable
    voter.find_votes.size.should == 1
    voter.votes.up.count.should == 1
  end

  it "should get all of the voters up votes" do
    voter.vote_up_for votable
    voter.find_up_votes.size.should == 1
    voter.votes.up.count.should == 1
  end

  it "should get all of the voters down votes" do
    voter.vote_down_for votable
    voter.find_down_votes.size.should == 1
    voter.votes.down.count.should == 1
  end

  it "should get all of the votes votes for a class" do
    votable.vote_by :voter => voter
    votable2.vote_by :voter => voter, :vote => false
    voter.find_votes_for_class(votable_klass).size.should == 2
    voter.votes.for_type(votable_klass).count.should == 2
  end

  it "should get all of the voters up votes for a class" do
    votable.vote_by :voter => voter
    votable2.vote_by :voter => voter, :vote => false
    voter.find_up_votes_for_class(votable_klass).size.should == 1
    voter.votes.up.for_type(votable_klass).count.should == 1
  end

  it "should get all of the voters down votes for a class" do
    votable.vote_by :voter => voter
    votable2.vote_by :voter => voter, :vote => false
    voter.find_down_votes_for_class(votable_klass).size.should == 1
    voter.votes.down.for_type(votable_klass).count.should == 1
  end

  it "should be contained to instances" do
    voter.vote :votable => votable, :vote => false
    voter2.vote :votable => votable

    voter.voted_as_when_voting_on(votable).should be false
  end

  describe '#find_voted_items' do
    it 'returns objects that a user has upvoted for' do
      votable.vote_by :voter => voter
      votable2.vote_by :voter => voter2
      voter.find_voted_items.should include votable
      voter.find_voted_items.size.should == 1
    end

    it 'returns objects that a user has upvoted for, using scope' do
      votable.vote_by :voter => voter, :vote_scope => 'rank'
      votable2.vote_by :voter => voter2, :vote_scope => 'rank'
      voter.find_voted_items(:vote_scope => 'rank').should include votable
      voter.find_voted_items(:vote_scope => 'rank').size.should == 1
    end

    it 'returns objects that a user has downvoted for' do
      votable.vote_down voter
      votable2.vote_down voter2
      voter.find_voted_items.should include votable
      voter.find_voted_items.size.should == 1
    end

    it 'returns objects that a user has downvoted for, using scope' do
      votable.vote_down voter, :vote_scope => 'rank'
      votable2.vote_down voter2, :vote_scope => 'rank'
      voter.find_voted_items(:vote_scope => 'rank').should include votable
      voter.find_voted_items(:vote_scope => 'rank').size.should == 1
    end
  end

  describe '#find_up_voted_items' do
    it 'returns objects that a user has upvoted for' do
      votable.vote_by :voter => voter
      votable2.vote_by :voter => voter2
      voter.find_up_voted_items.should include votable
      voter.find_up_voted_items.size.should == 1
      voter.find_liked_items.should include votable
      voter.find_liked_items.size.should == 1
    end

    it 'returns objects that a user has upvoted for, using scope' do
      votable.vote_by :voter => voter, :vote_scope => 'rank'
      votable2.vote_by :voter => voter2, :vote_scope => 'rank'
      voter.find_up_voted_items(:vote_scope => 'rank').should include votable
      voter.find_up_voted_items(:vote_scope => 'rank').size.should == 1
    end

    it 'does not return objects that a user has downvoted for' do
      votable.vote_down voter
      voter.find_up_voted_items.size.should == 0
    end

    it 'does not return objects that a user has downvoted for, using scope' do
      votable.vote_down voter, :vote_scope => 'rank'
      voter.find_up_voted_items(:vote_scope => 'rank').size.should == 0
    end
  end

  describe '#find_down_voted_items' do
    it 'does not return objects that a user has upvoted for' do
      votable.vote_by :voter => voter
      voter.find_down_voted_items.size.should == 0
    end

    it 'does not return objects that a user has upvoted for, using scope' do
      votable.vote_by :voter => voter, :vote_scope => 'rank'
      voter.find_down_voted_items(:vote_scope => 'rank').size.should == 0
    end

    it 'returns objects that a user has downvoted for' do
      votable.vote_down voter
      votable2.vote_down voter2
      voter.find_down_voted_items.should include votable
      voter.find_down_voted_items.size.should == 1
      voter.find_disliked_items.should include votable
      voter.find_disliked_items.size.should == 1
    end

    it 'returns objects that a user has downvoted for, using scope' do
      votable.vote_down voter, :vote_scope => 'rank'
      votable2.vote_down voter2, :vote_scope => 'rank'
      voter.find_down_voted_items(:vote_scope => 'rank').should include votable
      voter.find_down_voted_items(:vote_scope => 'rank').size.should == 1
    end

 end

  describe '#get_voted' do
    subject { voter.get_voted(votable.class) }

    it 'returns objects of a class that a voter has voted for' do
      votable.vote_by :voter => voter
      votable2.vote_down voter
      subject.should include votable
      subject.should include votable2
      subject.size.should == 2
    end

    it 'does not return objects of a class that a voter has voted for' do
      votable.vote_by :voter => voter2
      votable2.vote_by :voter => voter2
      subject.size.should == 0
    end
  end

  describe '#get_up_voted' do
    subject { voter.get_up_voted(votable.class) }

    it 'returns up voted items that a voter has voted for' do
      votable.vote_by :voter => voter
      subject.should include votable
      subject.size.should == 1
    end

    it 'does not return down voted items a voter has voted for' do
      votable.vote_down voter
      subject.size.should == 0
    end
  end

  describe '#get_down_voted' do
    subject { voter.get_down_voted(votable.class) }

    it 'does not return up voted items that a voter has voted for' do
      votable.vote_by :voter => voter
      subject.size.should == 0
    end

    it 'returns down voted items a voter has voted for' do
      votable.vote_down voter
      subject.should include votable
      subject.size.should == 1
    end
  end

end
