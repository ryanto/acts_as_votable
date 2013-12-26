require 'acts_as_votable'
require 'spec_helper'

describe VotableVoter do
  it_behaves_like "a votable_model" do
    # TODO Replace with factories
    let (:voter) { VotableVoter.create(:name => 'i can vote!') }
    let (:voter2) { VotableVoter.create(:name => 'a new person') }
    let (:votable) { VotableVoter.create(:name => 'a voting model') }
    let (:votable_cache) { VotableCache.create(:name => 'voting model with cache') }
  end

  it_behaves_like "a voter_model" do
    # TODO Replace with factories
    let (:voter) { VotableVoter.create(:name => 'i can vote!') }
    let (:voter2) { VotableVoter.create(:name => 'a new person') }
    let (:votable) { VotableVoter.create(:name => 'a voting model') }
    let (:votable2) { VotableVoter.create(:name => 'a 2nd voting model') }
  end
end
