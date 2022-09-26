class AuthenticationController < ApiController

	skip_before_action :authenticate_request, only: :login

	# POST /auth/login
	def login
		@user = User.find_by_username(params[:username])
		if @user&.authenticate(params[:password])
			token = jwt_encode(user_token: @user.token)
			render json: { token: token }, status: :ok
		else
			render json: { error: 'unauthorized' }, status: :unauthorized
		end
	end

	# GET /auth/logout
	def logout

	end

end
