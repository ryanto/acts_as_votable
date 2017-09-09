# frozen_string_literal: true

shared_examples "a voter_model" do
  let (:votable_klass) { votable.class }

  it "should be voted on after a voter has voted" do
    votable.vote_by voter: voter
    expect(voter.voted_on?(votable)).to be true
    expect(voter.voted_for?(votable)).to be true
  end

  it "should not be voted on if a voter has not voted" do
    expect(voter.voted_on?(votable)).to be false
  end

  it "should be voted on after a voter has voted under scope" do
    votable.vote_by voter: voter, vote_scope: "rank"
    expect(voter.voted_on?(votable, vote_scope: "rank")).to be true
  end

  it "should not be voted on other scope after a voter has voted under one scope" do
    votable.vote_by voter: voter, vote_scope: "rank"
    expect(voter.voted_on?(votable)).to be false
  end

  it "should be voted as true when a voter has voted true" do
    votable.vote_by voter: voter
    expect(voter.voted_as_when_voted_on(votable)).to be true
    expect(voter.voted_as_when_voted_for(votable)).to be true
  end

  it "should be voted as true when a voter has voted true under scope" do
    votable.vote_by voter: voter, vote_scope: "rank"
    expect(voter.voted_as_when_voted_for(votable, vote_scope: "rank")).to be true
  end

  it "should be voted as false when a voter has voted false" do
    votable.vote_by voter: voter, vote: false
    expect(voter.voted_as_when_voted_for(votable)).to be false
  end

  it "should be voted as false when a voter has voted false under scope" do
    votable.vote_by voter: voter, vote: false, vote_scope: "rank"
    expect(voter.voted_as_when_voted_for(votable, vote_scope: "rank")).to be false
  end

  it "should be voted as nil when a voter has never voted" do
    expect(voter.voted_as_when_voting_on(votable)).to be nil
  end

  it "should be voted as nil when a voter has never voted under the scope" do
    votable.vote_by voter: voter, vote: false, vote_scope: "rank"
    expect(voter.voted_as_when_voting_on(votable)).to be nil
  end

  it "should return true if voter has voted true" do
    votable.vote_by voter: voter
    expect(voter.voted_up_on?(votable)).to be true
  end

  it "should return false if voter has not voted true" do
    votable.vote_by voter: voter, vote: false
    expect(voter.voted_up_on?(votable)).to be false
  end

  it "should return true if the voter has voted false" do
    votable.vote_by voter: voter, vote: false
    expect(voter.voted_down_on?(votable)).to be true
  end

  it "should return false if the voter has not voted false" do
    votable.vote_by voter: voter, vote: true
    expect(voter.voted_down_on?(votable)).to be false
  end

  it "should provide reserve functionality, voter can vote on votable" do
    voter.vote votable: votable, vote: "bad"
    expect(voter.voted_as_when_voting_on(votable)).to be false
  end

  it "should allow the voter to vote up a model" do
    voter.vote_up_for votable
    expect(votable.get_up_votes.first.voter).to eq(voter)
    expect(votable.votes_for.up.first.voter).to eq(voter)
  end

  it "should allow the voter to vote down a model" do
    voter.vote_down_for votable
    expect(votable.get_down_votes.first.voter).to eq(voter)
    expect(votable.votes_for.down.first.voter).to eq(voter)
  end

  it "should allow the voter to unvote a model" do
    voter.vote_up_for votable
    voter.unvote_for votable
    expect(votable.find_votes_for.size).to eq(0)
    expect(votable.votes_for.count).to eq(0)
  end

  it "should get all of the voters votes" do
    voter.vote_up_for votable
    expect(voter.find_votes.size).to eq(1)
    expect(voter.votes.up.count).to eq(1)
  end

  it "should get all of the voters up votes" do
    voter.vote_up_for votable
    expect(voter.find_up_votes.size).to eq(1)
    expect(voter.votes.up.count).to eq(1)
  end

  it "should get all of the voters down votes" do
    voter.vote_down_for votable
    expect(voter.find_down_votes.size).to eq(1)
    expect(voter.votes.down.count).to eq(1)
  end

  it "should get all of the votes votes for a class" do
    votable.vote_by voter: voter
    votable2.vote_by voter: voter, vote: false
    expect(voter.find_votes_for_class(votable_klass).size).to eq(2)
    expect(voter.votes.for_type(votable_klass).count).to eq(2)
  end

  it "should get all of the voters up votes for a class" do
    votable.vote_by voter: voter
    votable2.vote_by voter: voter, vote: false
    expect(voter.find_up_votes_for_class(votable_klass).size).to eq(1)
    expect(voter.votes.up.for_type(votable_klass).count).to eq(1)
  end

  it "should get all of the voters down votes for a class" do
    votable.vote_by voter: voter
    votable2.vote_by voter: voter, vote: false
    expect(voter.find_down_votes_for_class(votable_klass).size).to eq(1)
    expect(voter.votes.down.for_type(votable_klass).count).to eq(1)
  end

  it "should be contained to instances" do
    voter.vote votable: votable, vote: false
    voter2.vote votable: votable

    expect(voter.voted_as_when_voting_on(votable)).to be false
  end

  describe "#find_voted_items" do
    it "returns objects that a user has upvoted for" do
      votable.vote_by voter: voter
      votable2.vote_by voter: voter2
      expect(voter.find_voted_items).to include votable
      expect(voter.find_voted_items.size).to eq(1)
    end

    it "returns objects that a user has upvoted for, using scope" do
      votable.vote_by voter: voter, vote_scope: "rank"
      votable2.vote_by voter: voter2, vote_scope: "rank"
      expect(voter.find_voted_items(vote_scope: "rank")).to include votable
      expect(voter.find_voted_items(vote_scope: "rank").size).to eq(1)
    end

    it "returns objects that a user has downvoted for" do
      votable.vote_down voter
      votable2.vote_down voter2
      expect(voter.find_voted_items).to include votable
      expect(voter.find_voted_items.size).to eq(1)
    end

    it "returns objects that a user has downvoted for, using scope" do
      votable.vote_down voter, vote_scope: "rank"
      votable2.vote_down voter2, vote_scope: "rank"
      expect(voter.find_voted_items(vote_scope: "rank")).to include votable
      expect(voter.find_voted_items(vote_scope: "rank").size).to eq(1)
    end
  end

  describe "#find_up_voted_items" do
    it "returns objects that a user has upvoted for" do
      votable.vote_by voter: voter
      votable2.vote_by voter: voter2
      expect(voter.find_up_voted_items).to include votable
      expect(voter.find_up_voted_items.size).to eq(1)
      expect(voter.find_liked_items).to include votable
      expect(voter.find_liked_items.size).to eq(1)
    end

    it "returns objects that a user has upvoted for, using scope" do
      votable.vote_by voter: voter, vote_scope: "rank"
      votable2.vote_by voter: voter2, vote_scope: "rank"
      expect(voter.find_up_voted_items(vote_scope: "rank")).to include votable
      expect(voter.find_up_voted_items(vote_scope: "rank").size).to eq(1)
    end

    it "does not return objects that a user has downvoted for" do
      votable.vote_down voter
      expect(voter.find_up_voted_items.size).to eq(0)
    end

    it "does not return objects that a user has downvoted for, using scope" do
      votable.vote_down voter, vote_scope: "rank"
      expect(voter.find_up_voted_items(vote_scope: "rank").size).to eq(0)
    end
  end

  describe "#find_down_voted_items" do
    it "does not return objects that a user has upvoted for" do
      votable.vote_by voter: voter
      expect(voter.find_down_voted_items.size).to eq(0)
    end

    it "does not return objects that a user has upvoted for, using scope" do
      votable.vote_by voter: voter, vote_scope: "rank"
      expect(voter.find_down_voted_items(vote_scope: "rank").size).to eq(0)
    end

    it "returns objects that a user has downvoted for" do
      votable.vote_down voter
      votable2.vote_down voter2
      expect(voter.find_down_voted_items).to include votable
      expect(voter.find_down_voted_items.size).to eq(1)
      expect(voter.find_disliked_items).to include votable
      expect(voter.find_disliked_items.size).to eq(1)
    end

    it "returns objects that a user has downvoted for, using scope" do
      votable.vote_down voter, vote_scope: "rank"
      votable2.vote_down voter2, vote_scope: "rank"
      expect(voter.find_down_voted_items(vote_scope: "rank")).to include votable
      expect(voter.find_down_voted_items(vote_scope: "rank").size).to eq(1)
    end

  end

  describe "#get_voted" do
    subject { voter.get_voted(votable.class) }

    it "returns objects of a class that a voter has voted for" do
      votable.vote_by voter: voter
      votable2.vote_down voter
      expect(subject).to include votable
      expect(subject).to include votable2
      expect(subject.size).to eq(2)
    end

    it "does not return objects of a class that a voter has voted for" do
      votable.vote_by voter: voter2
      votable2.vote_by voter: voter2
      expect(subject.size).to eq(0)
    end
  end

  describe "#get_up_voted" do
    subject { voter.get_up_voted(votable.class) }

    it "returns up voted items that a voter has voted for" do
      votable.vote_by voter: voter
      expect(subject).to include votable
      expect(subject.size).to eq(1)
    end

    it "does not return down voted items a voter has voted for" do
      votable.vote_down voter
      expect(subject.size).to eq(0)
    end
  end

  describe "#get_down_voted" do
    subject { voter.get_down_voted(votable.class) }

    it "does not return up voted items that a voter has voted for" do
      votable.vote_by voter: voter
      expect(subject.size).to eq(0)
    end

    it "returns down voted items a voter has voted for" do
      votable.vote_down voter
      expect(subject).to include votable
      expect(subject.size).to eq(1)
    end
  end
end
