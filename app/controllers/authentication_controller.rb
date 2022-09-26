class AuthenticationController < ApiController
	include ActionController::HttpAuthentication::Basic::ControllerMethods

	skip_before_action :authenticate_request, only: :login

	# POST /auth/login
	def login
		# Use basic auth to authenticate user
		authenticate_or_request_with_http_basic do |given_name, given_password|
			@user = User.find_by_username(given_name)
		    if @user&.authenticate(given_password)

		    	@user.refresh_token!

				token = jwt_encode(user_token: @user.token)
				render json: { user_token: token }, status: :ok
			end
		end
	end

	# PUT /auth/logout
	def logout
		if @current_user
			@current_user.delete_token
			render status: :ok
		else
			render status: :unauthorized
		end
	end

	# GET /auth/ping
	def ping
		if @current_user
			render status: :ok
		else
			render status: :unauthorized
		end
	end


end
