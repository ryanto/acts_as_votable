# frozen_string_literal: true

require "spec_helper"

describe ActsAsVotable::Votable do
  it "should not be votable" do
    expect(NotVotable).not_to be_votable
  end

  it "should be votable" do
    expect(Votable).to be_votable
  end

  it_behaves_like "a votable_model" do
    let (:voter)         { create(:voter, name: "i can vote!") }
    let (:voter2)        { create(:voter, name: "a new person") }
    let (:voter3)        { create(:voter, name: "another person") }
    let (:votable)       { create(:votable, name: "a voting model") }
    let (:votable_cache) { create(:votable_cache, name: "voting model with cache") }
  end
end
