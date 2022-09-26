class ApiController < ApplicationController

    include JsonWebToken

    before_action :authenticate_request

    private

    	def authenticate_request
    		header = request.headers["Authorization"]
    		header = header.split(" ").last if header
    		decoded = jwt_decode(header)
            user_token = decoded[:user_token]
            return if user_token.blank?
            # puts "USER_TOKE: #{user_token}"
    		@current_user = User.find_by_token(user_token)
        rescue 
            @current_user = nil
    	end

end