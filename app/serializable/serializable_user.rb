class SerializableUser < JSONAPI::Serializable::Resource
	type 'users'
	attributes :username, :role
end