module ActsAsVotable
  module Searchable
  
    def self.included(base)
      base.send :extend, ActsAsVotable::Searchable::ClassMethods
    end
    
    module ClassMethods
      def best
        joins("LEFT JOIN votes ON votes.votable_id = #{table_name}.id AND votes.votable_type='#{self.class.name}'").group("#{table_name}.id").order("COUNT(*) - SUM(votes.vote_flag) DESC")
      end
      
      #
      # NOTE: this thing seem not to be working in sqlite3 db, cause of sum among boolean values. In MySQL things seem to be ok
      #
      def worst
        joins("LEFT JOIN votes ON votes.votable_id = #{table_name}.id AND votes.votable_type='#{self.class.name}'").group("#{table_name}.id").order("COUNT(*) - SUM(votes.vote_flag) ASC")
      end
    end
  
  end
end
