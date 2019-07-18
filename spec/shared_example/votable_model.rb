# frozen_string_literal: true

shared_examples "a votable_model" do
  it "should return false when a vote with no voter is saved" do
    expect(votable.vote_by).to be false
  end

  it "should have one vote when saved" do
    votable.vote_by voter: voter, vote: "yes"
    expect(votable.votes_for.size).to eq(1)
  end

  it "should have one vote when voted on twice by the same person" do
    votable.vote_by voter: voter, vote: "yes"
    votable.vote_by voter: voter, vote: "no"
    expect(votable.votes_for.size).to eq(1)
  end

  it "should have two votes_for when voted on twice by the same person with duplicate paramenter" do
    votable.vote_by voter: voter, vote: "yes"
    votable.vote_by voter: voter, vote: "no", duplicate: true
    expect(votable.votes_for.size).to eq(2)
  end

  it "should have one scoped vote when voting under an scope" do
    votable.vote_by voter: voter, vote: "yes", vote_scope: "rank"
    expect(votable.find_votes_for(vote_scope: "rank").size).to eq(1)
  end

  it "should have one vote when voted on twice using scope by the same person" do
    votable.vote_by voter: voter, vote: "yes", vote_scope: "rank"
    votable.vote_by voter: voter, vote: "no", vote_scope: "rank"
    expect(votable.find_votes_for(vote_scope: "rank").size).to eq(1)
  end

  it "should have two votes_for when voting on two different scopes by the same person" do
    votable.vote_by voter: voter, vote: "yes", vote_scope: "weekly_rank"
    votable.vote_by voter: voter, vote: "no", vote_scope: "monthly_rank"
    expect(votable.votes_for.size).to eq(2)
  end

  it "should be callable with vote_up" do
    votable.vote_up voter
    expect(votable.get_up_votes.first.voter).to eq(voter)
  end

  it "should be callable with vote_down" do
    votable.vote_down voter
    expect(votable.get_down_votes.first.voter).to eq(voter)
  end

  it "should have 2 votes_for when voted on once by two different people" do
    votable.vote_by voter: voter
    votable.vote_by voter: voter2
    expect(votable.votes_for.size).to eq(2)
  end

  it "should have one true vote" do
    votable.vote_by voter: voter
    votable.vote_by voter: voter2, vote: "dislike"
    expect(votable.get_up_votes.size).to eq(1)
  end

  it "should have 2 false votes_for" do
    votable.vote_by voter: voter, vote: "no"
    votable.vote_by voter: voter2, vote: "dislike"
    expect(votable.get_down_votes.size).to eq(2)
  end

  it "should have been voted on by voter2" do
    votable.vote_by voter: voter2, vote: true
    expect(votable.find_votes_for.first.voter.id).to be voter2.id
  end

  it "should count the vote as registered if this is the voters first vote" do
    votable.vote_by voter: voter
    expect(votable.vote_registered?).to be true
  end

  it "should not count the vote as being registered if that voter has already voted and the vote has not changed" do
    votable.vote_by voter: voter, vote: true
    votable.vote_by voter: voter, vote: "yes"
    expect(votable.vote_registered?).to be false
  end

  it "should count the vote as registered if the voter has voted and the vote flag has changed" do
    votable.vote_by voter: voter, vote: true
    votable.vote_by voter: voter, vote: "dislike"
    expect(votable.vote_registered?).to be true
  end

  it "should count the vote as registered if the voter has voted and the vote weight has changed" do
    votable.vote_by voter: voter, vote: true, vote_weight: 1
    votable.vote_by voter: voter, vote: true, vote_weight: 2
    expect(votable.vote_registered?).to be true
  end

  it "should be voted on by voter" do
    votable.vote_by voter: voter
    expect(votable.voted_on_by?(voter)).to be true
  end

  it "should be able to unvote a voter" do
    votable.liked_by(voter)
    votable.unliked_by(voter)
    expect(votable.voted_on_by?(voter)).to be false
  end

  it "should be voted up by a voter" do
    votable.liked_by voter
    expect(votable.voted_up_by?(voter)).to be true
  end

  it "should be voted down by a voter" do
    votable.disliked_by voter
    expect(votable.voted_down_by?(voter)).to be true
  end

  it "should unvote a positive vote" do
    votable.vote_by voter: voter
    votable.unvote voter: voter
    expect(votable.find_votes_for.count).to eq(0)
  end

  it "should set the votable to unregistered after unvoting" do
    votable.vote_by voter: voter
    votable.unvote voter: voter
    expect(votable.vote_registered?).to be false
  end

  it "should unvote a negative vote" do
    votable.vote_by voter: voter, vote: "no"
    votable.unvote voter: voter
    expect(votable.find_votes_for.count).to eq(0)
  end

  it "should unvote only the from a single voter" do
    votable.vote_by voter: voter
    votable.vote_by voter: voter2
    votable.unvote voter: voter
    expect(votable.find_votes_for.count).to eq(1)
  end

  it "should be contained to instances" do
    votable2 = build(:votable, name: "2nd votable")
    votable2.save

    votable.vote_by voter: voter, vote: false
    votable2.vote_by voter: voter, vote: true
    votable2.vote_by voter: voter, vote: true

    expect(votable.vote_registered?).to be true
    expect(votable2.vote_registered?).to be false
  end

  it "should set default vote weight to 1 if not specified" do
    votable.upvote_by voter
    expect(votable.find_votes_for.first.vote_weight).to eq(1)
  end

  describe "with cached votes_for" do
    let!(:voter)         { create(:voter, name: "i can vote!") }
    let!(:votable)       { create(:votable, name: "a voting model without a cache") }
    let!(:votable_cache) { create(:votable_cache, name: "voting model with cache") }

    it "should not update cached votes_for if there are no columns" do
      votable.vote_by voter: voter
    end

    it "should update cached total votes_for if there is a total column" do
      votable_cache.cached_votes_total = 50
      votable_cache.vote_by voter: voter
      expect(votable_cache.cached_votes_total).to eq(1)
    end

    describe "with ActiveRecord::StaleObjectError" do
      it "should rollback vote up if cache update fails" do
        votable_cache.cached_votes_total = 50
        expect(votable_cache)
          .to(receive(:update_cached_votes)
          .and_raise(ActiveRecord::StaleObjectError.new(votable_cache, "update")))

        expect { votable_cache.vote_by voter: voter }.to raise_error ActiveRecord::StaleObjectError
        expect(votable_cache.cached_votes_total).to eq(50)
        expect(votable_cache.voted_on_by?(voter)).to be false
      end

      it "should rollback unvote if cache update fails" do
        votable_cache.vote_by voter: voter, vote: "true"

        expect(votable_cache)
          .to(receive(:update_cached_votes)
          .and_raise(ActiveRecord::StaleObjectError.new(votable_cache, "update")))

        expect { votable_cache.unvote voter: voter }.to raise_error ActiveRecord::StaleObjectError

        expect(votable_cache.cached_votes_total).to eq(1)
        expect(votable_cache.voted_on_by?(voter)).to be true
      end
    end

    it "should update cached total votes_for when a vote up is removed" do
      votable_cache.vote_by voter: voter, vote: "true"
      votable_cache.unvote voter: voter
      expect(votable_cache.cached_votes_total).to eq(0)
    end

    it "should update cached total votes_for when a vote down is removed" do
      votable_cache.vote_by voter: voter, vote: "false"
      votable_cache.unvote voter: voter
      expect(votable_cache.cached_votes_total).to eq(0)
    end

    it "should update cached score votes_for if there is a score column" do
      votable_cache.cached_votes_score = 50
      votable_cache.vote_by voter: voter
      expect(votable_cache.cached_votes_score).to eq(1)
      votable_cache.vote_by voter: voter2, vote: "false"
      expect(votable_cache.cached_votes_score).to eq(0)
      votable_cache.vote_by voter: voter, vote: "false"
      expect(votable_cache.cached_votes_score).to eq(-2)
    end

    it "should update cached score votes_for when a vote up is removed" do
      votable_cache.vote_by voter: voter, vote: "true"
      expect(votable_cache.cached_votes_score).to eq(1)
      votable_cache.unvote voter: voter
      expect(votable_cache.cached_votes_score).to eq(0)
    end

    it "should update cached score votes_for when a vote down is removed" do
      votable_cache.vote_by voter: voter, vote: "false"
      expect(votable_cache.cached_votes_score).to eq(-1)
      votable_cache.unvote voter: voter
      expect(votable_cache.cached_votes_score).to eq(0)
    end

    it "should update cached weighted total if there is a weighted total column" do
      votable_cache.cached_weighted_total = 50
      votable_cache.vote_by voter: voter
      expect(votable_cache.cached_weighted_total).to eq(1)
      votable_cache.vote_by voter: voter2, vote: "false"
      expect(votable_cache.cached_weighted_total).to eq(2)
    end

    it "should update cached weighted total votes_for when a vote up is removed" do
      votable_cache.vote_by voter: voter, vote: "true", vote_weight: 3
      expect(votable_cache.cached_weighted_total).to eq(3)
      votable_cache.unvote voter: voter
      expect(votable_cache.cached_weighted_total).to eq(0)
    end

    it "should update cached weighted total votes_for when a vote down is removed" do
      votable_cache.vote_by voter: voter, vote: "false", vote_weight: 4
      expect(votable_cache.cached_weighted_total).to eq(4)
      votable_cache.unvote voter: voter
      expect(votable_cache.cached_weighted_total).to eq(0)
    end

    it "should update cached weighted score if there is a weighted score column" do
      votable_cache.cached_weighted_score = 50
      votable_cache.vote_by voter: voter, vote_weight: 3
      expect(votable_cache.cached_weighted_score).to eq(3)
      votable_cache.vote_by voter: voter2, vote: "false", vote_weight: 5
      expect(votable_cache.cached_weighted_score).to eq(-2)
      # voter changes her vote from 3 to 5
      votable_cache.vote_by voter: voter, vote_weight: 5
      expect(votable_cache.cached_weighted_score).to eq(0)
      votable_cache.vote_by voter: voter3, vote_weight: 4
      expect(votable_cache.cached_weighted_score).to eq(4)
    end

    it "should update cached weighted score votes_for when a vote up is removed" do
      votable_cache.vote_by voter: voter, vote: "true", vote_weight: 3
      expect(votable_cache.cached_weighted_score).to eq(3)
      votable_cache.unvote voter: voter
      expect(votable_cache.cached_weighted_score).to eq(0)
    end

    it "should update cached weighted score votes_for when a vote down is removed" do
      votable_cache.vote_by voter: voter, vote: "false", vote_weight: 4
      expect(votable_cache.cached_weighted_score).to eq(-4)
      votable_cache.unvote voter: voter
      expect(votable_cache.cached_weighted_score).to eq(0)
    end

    it "should update cached weighted average if there is a weighted average column" do
      votable_cache.cached_weighted_average = 50.0
      votable_cache.vote_by voter: voter, vote: "true", vote_weight: 5
      expect(votable_cache.cached_weighted_average).to eq(5.0)
      votable_cache.vote_by voter: voter2, vote: "true", vote_weight: 3
      expect(votable_cache.cached_weighted_average).to eq(4.0)
      # voter changes her vote from 5 to 4
      votable_cache.vote_by voter: voter, vote: "true", vote_weight: 4
      expect(votable_cache.cached_weighted_average).to eq(3.5)
      votable_cache.vote_by voter: voter3, vote: "true", vote_weight: 5
      expect(votable_cache.cached_weighted_average).to eq(4.0)
    end

    it "should update cached weighted average votes_for when a vote up is removed" do
      votable_cache.vote_by voter: voter, vote: "true", vote_weight: 5
      votable_cache.vote_by voter: voter2, vote: "true", vote_weight: 3
      expect(votable_cache.cached_weighted_average).to eq(4)
      votable_cache.unvote voter: voter
      expect(votable_cache.cached_weighted_average).to eq(3)
    end

    it "should update cached up votes_for if there is an up vote column" do
      votable_cache.cached_votes_up = 50
      votable_cache.vote_by voter: voter
      votable_cache.vote_by voter: voter
      expect(votable_cache.cached_votes_up).to eq(1)
    end

    it "should update cached down votes_for if there is a down vote column" do
      votable_cache.cached_votes_down = 50
      votable_cache.vote_by voter: voter, vote: "false"
      expect(votable_cache.cached_votes_down).to eq(1)
    end

    it "should update cached up votes_for when a vote up is removed" do
      votable_cache.vote_by voter: voter, vote: "true"
      votable_cache.unvote voter: voter
      expect(votable_cache.cached_votes_up).to eq(0)
    end

    it "should update cached down votes_for when a vote down is removed" do
      votable_cache.vote_by voter: voter, vote: "false"
      votable_cache.unvote voter: voter
      expect(votable_cache.cached_votes_down).to eq(0)
    end

    it "should select from cached total votes_for if there a total column" do
      votable_cache.vote_by voter: voter
      votable_cache.cached_votes_total = 50
      expect(votable_cache.count_votes_total).to eq(50)
    end

    it "should select from cached up votes_for if there is an up vote column" do
      votable_cache.vote_by voter: voter
      votable_cache.cached_votes_up = 50
      expect(votable_cache.count_votes_up).to eq(50)
    end

    it "should select from cached down votes_for if there is a down vote column" do
      votable_cache.vote_by voter: voter, vote: "false"
      votable_cache.cached_votes_down = 50
      expect(votable_cache.count_votes_down).to eq(50)
    end

    it "should select from cached votes score if there is a votes score column" do
      votable_cache.vote_by voter: voter, vote: "false"
      votable_cache.cached_votes_score = 50
      expect(votable_cache.count_votes_score).to eq(50)
    end

    it "should select from cached weighted total if there is a weighted total column" do
      votable_cache.vote_by voter: voter, vote: "false"
      votable_cache.cached_weighted_total = 50
      expect(votable_cache.weighted_total).to eq(50)
    end

    it "should select from cached weighted score if there is a weighted score column" do
      votable_cache.vote_by voter: voter, vote: "false"
      votable_cache.cached_weighted_score = 50
      expect(votable_cache.weighted_score).to eq(50)
    end

    it "should select from cached weighted average if there is a weighted average column" do
      votable_cache.vote_by voter: voter, vote: "false"
      votable_cache.cached_weighted_average = 50
      expect(votable_cache.weighted_average).to eq(50)
    end

    it "should update cached total votes_for when voting under an scope" do
      votable_cache.vote_by voter: voter, vote: "true", vote_scope: "rank"
      expect(votable_cache.cached_votes_total).to eq(1)
    end

    it "should update cached up votes_for when voting under an scope" do
      votable_cache.vote_by voter: voter, vote: "true", vote_scope: "rank"
      expect(votable_cache.cached_votes_up).to eq(1)
    end

    it "should update cached total votes_for when a scoped vote down is removed" do
      votable_cache.vote_by voter: voter, vote: "true", vote_scope: "rank"
      votable_cache.unvote voter: voter, vote_scope: "rank"
      expect(votable_cache.cached_votes_total).to eq(0)
    end

    it "should update cached up votes_for when a scoped vote down is removed" do
      votable_cache.vote_by voter: voter, vote: "true", vote_scope: "rank"
      votable_cache.unvote voter: voter, vote_scope: "rank"
      expect(votable_cache.cached_votes_up).to eq(0)
    end

    it "should update cached down votes_for when downvoting under a scope" do
      votable_cache.vote_by voter: voter, vote: "false", vote_scope: "rank"
      expect(votable_cache.cached_votes_down).to eq(1)
    end

    it "should update cached down votes_for when a scoped vote down is removed" do
      votable_cache.vote_by voter: voter, vote: "false", vote_scope: "rank"
      votable_cache.unvote voter: voter, vote_scope: "rank"
      expect(votable_cache.cached_votes_down).to eq(0)
    end

    describe "with acts_as_votable_options" do
      describe "cacheable_strategy" do
        let(:updated_at) { 3.days.ago }

        before { votable_cache.vote_by voter: voter }

        context "update" do
          let(:votable_cache) { create(:votable_cache_update, name: "voting model with cache", updated_at: updated_at) }

          it do
            expect(votable_cache.cached_votes_total).to eq(1)
            expect(votable_cache.updated_at.to_i).to_not eq updated_at.to_i
          end
        end

        context "update_columns" do
          let(:votable_cache) { create(:votable_cache_update_columns, name: "voting model with cache", updated_at: updated_at) }

          it do
            expect(votable_cache.cached_votes_total).to eq(1)
            expect(votable_cache.updated_at.to_i).to eq updated_at.to_i
          end
        end
      end
    end
  end

  describe "with scoped cached votes_for" do

    it "should update cached total votes_for if there is a total column" do
      votable_cache.cached_scoped_test_votes_total = 50
      votable_cache.vote_by voter: voter, vote_scope: "test"
      expect(votable_cache.cached_scoped_test_votes_total).to eq(1)
    end

    it "should update cached total votes_for when a vote up is removed" do
      votable_cache.vote_by voter: voter, vote: "true", vote_scope: "test"
      votable_cache.unvote voter: voter, vote_scope: "test"
      expect(votable_cache.cached_scoped_test_votes_total).to eq(0)
    end

    it "should update cached total votes_for when a vote down is removed" do
      votable_cache.vote_by voter: voter, vote: "false", vote_scope: "test"
      votable_cache.unvote voter: voter, vote_scope: "test"
      expect(votable_cache.cached_scoped_test_votes_total).to eq(0)
    end

    it "should update cached score votes_for if there is a score column" do
      votable_cache.cached_scoped_test_votes_score = 50
      votable_cache.vote_by voter: voter, vote_scope: "test"
      expect(votable_cache.cached_scoped_test_votes_score).to eq(1)
      votable_cache.vote_by voter: voter2, vote: "false", vote_scope: "test"
      expect(votable_cache.cached_scoped_test_votes_score).to eq(0)
      votable_cache.vote_by voter: voter, vote: "false", vote_scope: "test"
      expect(votable_cache.cached_scoped_test_votes_score).to eq(-2)
    end

    it "should update cached score votes_for when a vote up is removed" do
      votable_cache.vote_by voter: voter, vote: "true", vote_scope: "test"
      expect(votable_cache.cached_scoped_test_votes_score).to eq(1)
      votable_cache.unvote voter: voter, vote_scope: "test"
      expect(votable_cache.cached_scoped_test_votes_score).to eq(0)
    end

    it "should update cached score votes_for when a vote down is removed" do
      votable_cache.vote_by voter: voter, vote: "false", vote_scope: "test"
      expect(votable_cache.cached_scoped_test_votes_score).to eq(-1)
      votable_cache.unvote voter: voter, vote_scope: "test"
      expect(votable_cache.cached_scoped_test_votes_score).to eq(0)
    end

    it "should update cached up votes_for if there is an up vote column" do
      votable_cache.cached_scoped_test_votes_up = 50
      votable_cache.vote_by voter: voter, vote_scope: "test"
      votable_cache.vote_by voter: voter, vote_scope: "test"
      expect(votable_cache.cached_scoped_test_votes_up).to eq(1)
    end

    it "should update cached down votes_for if there is a down vote column" do
      votable_cache.cached_scoped_test_votes_down = 50
      votable_cache.vote_by voter: voter, vote: "false", vote_scope: "test"
      expect(votable_cache.cached_scoped_test_votes_down).to eq(1)
    end

    it "should update cached up votes_for when a vote up is removed" do
      votable_cache.vote_by voter: voter, vote: "true", vote_scope: "test"
      votable_cache.unvote voter: voter, vote_scope: "test"
      expect(votable_cache.cached_scoped_test_votes_up).to eq(0)
    end

    it "should update cached down votes_for when a vote down is removed" do
      votable_cache.vote_by voter: voter, vote: "false", vote_scope: "test"
      votable_cache.unvote voter: voter, vote_scope: "test"
      expect(votable_cache.cached_scoped_test_votes_down).to eq(0)
    end

    it "should select from cached total votes_for if there a total column" do
      votable_cache.vote_by voter: voter, vote_scope: "test"
      votable_cache.cached_scoped_test_votes_total = 50
      expect(votable_cache.count_votes_total(false, "test")).to eq(50)
    end

    it "should select from cached up votes_for if there is an up vote column" do
      votable_cache.vote_by voter: voter, vote_scope: "test"
      votable_cache.cached_scoped_test_votes_up = 50
      expect(votable_cache.count_votes_up(false, "test")).to eq(50)
    end

    it "should select from cached down votes_for if there is a down vote column" do
      votable_cache.vote_by voter: voter, vote: "false", vote_scope: "test"
      votable_cache.cached_scoped_test_votes_down = 50
      expect(votable_cache.count_votes_down(false, "test")).to eq(50)
    end

  end

  describe "sti models" do
    let(:child_sti_not_votable) { create(:child_of_sti_not_votable, name: "sti child") }
    let(:child_sti_votable)     { create(:child_of_sti_votable, name: "sti child") }

    it "should be able to vote on a votable child of a non votable sti model" do
      child_sti_not_votable.vote_by voter: voter, vote: "yes"
      expect(child_sti_not_votable.votes_for.size).to eq(1)
    end

    it "should not be able to vote on a parent non votable" do
      expect(StiNotVotable).not_to be_votable
    end

    it "should be able to vote on a child when its parent is votable" do
      child_sti_votable.vote_by voter: voter, vote: "yes"
      expect(child_sti_votable.votes_for.size).to eq(1)
    end
  end
end
