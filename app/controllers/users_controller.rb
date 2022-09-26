class UsersController < ApplicationController

	extend ActionController::HttpAuthentication::Basic::ControllerMethods::ClassMethods
	include ActionController::HttpAuthentication::Basic::ControllerMethods

    http_basic_authenticate_with name: ENV["JSON_API__MASTER_USERNAME"], 
                                 password: ENV["JSON_API__MASTER_SECRET"]

    before_action :set_user, only: [:show, :destroy, :update]

	# GET /users
	def index
		# Show first 20
		users = Kredis.redis.keys("*users*")[0..20].map { |name| User.find_by_username(name.split(":")[1]) }
		render jsonapi: users
	end 

	# GET /users/{username}
	def show
		render jsonapi: @user, status: :ok
	end

	# POST /users
	def create 
		@user = User.new(user_params)
		@user.generate_token

		if @user.save(:create)
			render jsonapi: @user, status: :created
		else
			render jsonapi_errors: @user.errors, status: :unprocessable_entity
		end
	end 

	# PUT /users/{username}
	def update  
		unless @user.update(user_params)
			render jsonapi_errors: @user.errors, status: :unprocessable_entity
		end

		render status: :ok
	end

	# DELETE /users/{username}
	def destroy 
		@user.destroy

		render status: :ok
	end 

	private 

		def user_params
			params.permit(:username, :password, :role)
		end

		def set_user
			@user = User.find_by_username(params[:id])
			render status: :not_found and return if @user.blank?
		end

end
