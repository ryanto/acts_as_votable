# frozen_string_literal: true

require "spec_helper"

describe ActsAsVotable::Voter do
  it "should not be a voter" do
    expect(NotVotable).not_to be_votable
  end

  it "should be a voter" do
    expect(Votable).to be_votable
  end

  it_behaves_like "a voter_model" do
    let (:voter)    { create(:voter, name: "i can vote!") }
    let (:voter2)   { create(:voter, name: "a new person") }
    let (:votable)  { create(:votable, name: "a voting model") }
    let (:votable2) { create(:votable, name: "a 2nd voting model") }
  end
end
