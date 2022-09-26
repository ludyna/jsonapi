class User
	include ActiveModel::Validations
	include ActiveModel::SecurePassword

 	ROLES = %w(admin user other).freeze

 	# We will not persist password, only password_digest. Also role might be useful for future.
	PERSISTENT_ATTRIBUTES = %i(password_digest role token).freeze
	PERSISTENT_ATTRIBUTES_STRINGS = User::PERSISTENT_ATTRIBUTES.map(&:to_s).freeze

	ALL_ATTRIBUTES = (%i(username password) + PERSISTENT_ATTRIBUTES).freeze
	ALL_ATTRIBUTES_STRINGS = User::ALL_ATTRIBUTES.map(&:to_s).freeze

	# Create all attribute accessors but exclude password, 
	# because it is already created in ActiveModel::SecurePassword
	attr_accessor *(User::ALL_ATTRIBUTES - %i(password))
	
	# This is for compatibility with jsonapi-rb json renderers
	def id 
		self.username
	end 

	validates :username, presence: true, length: 3..100
	validates :role, inclusion: User::ROLES
	validates :token, presence: true, length: 32..32
	validates :password, presence: true, length: 6..32
	validate :validate_unique_user, on: :create

	has_secure_password

	class << self

		def find_by_username(username)
			
			raise ArgumentError.new(:username) if username.blank?

			redis_key = user_redis_key(username)

			raise ActiveRecord::RecordNotFound if !Kredis.redis.exists?(redis_key)

			kredis_user = Kredis.hash redis_key, typed: :string
			user_hash = kredis_user.to_h

			raise ActiveRecord::RecordNotFound if user_hash.blank? 

			user = User.new

			user.username = username

			user.set_from_params(user_hash)

			user
		end

		def find_by_token(token)
			kredis_string = Kredis.string token_redis_key(token)
			username = kredis_string.value

			raise ActiveRecord::RecordNotFound if username.blank?

			find_by_username(username)
		end 

		def user_redis_key(username)
			"users:#{username}"
		end

		def token_redis_key(token)
			"tokens:#{token}"
		end 
	end

	def initialize(params=nil) 
		set_from_params(params.to_h.with_indifferent_access) if params.present?

		# Default role
		self.role = "user" if self.role.blank? 
	end 

	def save(context=:save)
		self.validate(context)
		 
		return nil if self.errors.present?

		user_redis_key = User.user_redis_key(self.username)
 		kredis_user = Kredis.hash user_redis_key, typed: :string

 		temp = {}
		PERSISTENT_ATTRIBUTES_STRINGS.each do |key|
			temp[key] = self.send(key).to_s
		end

		kredis_user.update(**temp)
		self
	end

	def update(params)
		if params.present?
			set_from_params(params.to_h.with_indifferent_access)

			# On update, update user token too
			generate_token

			return save(:update)
		end

		return nil
	end

	def destroy
		return if self.username.blank?

		if self.token.present?
			redis_key = User.token_redis_key(self.token)
			Kredis.redis.del(redis_key) if Kredis.redis.exists?(redis_key)
		end

		redis_key = User.user_redis_key(self.username)
		Kredis.redis.del(redis_key) if Kredis.redis.exists?(redis_key)
	end

	def generate_token(exp=30.minutes.from_now)

		# Delete old token
		if self.token.present?
			redis_key = User.token_redis_key(self.token)
			Kredis.redis.del(redis_key) if Kredis.redis.exists?(redis_key)
		end

		# Create and set new token
		while true
			token = String.random
			kredis_string = Kredis.string User.token_redis_key(token), expires_in: exp

			# Make sure token doesn't exist already
			if kredis_string.value.blank?
				kredis_string.value = self.username
				break
			end
		end

		self.token = token
	end

	def set_from_params(params)
		# Whitelisting hash attributes before assigning them to User's attributes
		(User::ALL_ATTRIBUTES_STRINGS & params.keys).each do |key|
			self.send "#{key}=", params[key]
		end
	end 

	def validate_unique_user
		user_redis_key = User.user_redis_key(self.username)

		if Kredis.redis.exists?(user_redis_key)
			self.errors.add(:base, :invalid, message: "User already exists")
		end
	end 
end