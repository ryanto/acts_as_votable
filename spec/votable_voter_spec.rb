# frozen_string_literal: true

require "spec_helper"

describe VotableVoter do
  it_behaves_like "a votable_model" do
    let (:voter)         { create(:votable_voter, name: "i can vote!") }
    let (:voter2)        { create(:votable_voter, name: "a new person") }
    let (:voter3)        { create(:voter, name: "another person") }
    let (:votable)       { create(:votable_voter, name: "a voting model") }
    let (:votable_cache) { create(:votable_cache, name: "voting model with cache") }
  end

  it_behaves_like "a voter_model" do
    let (:voter)    { create(:votable_voter, name: "i can vote!") }
    let (:voter2)   { create(:votable_voter, name: "a new person") }
    let (:votable)  { create(:votable_voter, name: "a voting model") }
    let (:votable2) { create(:votable_voter, name: "a 2nd voting model") }
  end
end
