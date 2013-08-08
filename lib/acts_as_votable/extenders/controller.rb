module ActsAsVotable
  module Extenders

    module Controller

      def voter_params(params_object = params[:vote])
        params_object.permit(:votable_id, :votable_type,
          :voter_id, :voter_type,
          :votable, :voter,
          :vote_flag, :vote_scope)
      end
      
      def votable_params(params_object = params[:vote])
        params_object.permit(:vote_registered)
      end
      
    end
  end
end
