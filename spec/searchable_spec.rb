require 'acts_as_votable'
require 'spec_helper'

describe ActsAsVotable::Searchable do

  before(:each) do
    clean_database
    @voters = (0..9).map{ |i| Voter.new(:name => "Voter#{i}")}
    @voters.each &:save
    @votables = (0..4).map{ |i| Votable.new(:name => "Model#{i}") }
    @votables.each &:save
    
    for i in (0..4)
      for j in (0..9)
        if j <= i
          @votables[i].vote_down @voters[j]
        else
          @votables[i].vote_up @voters[j]
        end
      end
    end
    
  end

  it "allow to search for best records" do
    Votable.best.all.first.should == @votables.sort(){ |a,b| b.rating <=> a.rating }.first
    
    @db_records = Votable.best.all
    @sorted = @votables.sort(){ |a,b| b.rating <=> a.rating }
    
    for i in (0..@db_records.count - 1)
      @db_records[i].should == @sorted[i]
    end
  end
  
  it "should allow to search for worst records" do
    
    @db_records = Votable.worst.all
    @sorted = @votables.sort(){ |a,b| a.rating <=> b.rating }
    
    
    for i in (0..@db_records.count - 1)
      @db_records[i].should == @sorted[i]
    end
  end

end
