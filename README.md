# Hello

## Gems

I am using the next gems:

    # Redis client
    gem "redis", "~> 5.0.5" 
    # Adds a Redis::Namespace class which can be used to namespace calls to Redis
    gem "redis-namespace", "~> 1.9.0" 
    # Higher-level data structures built on Redis.
    gem "kredis", "~> 1.3.0" 
    # A pure ruby implementation of the RFC 7519 OAuth JSON Web Token (JWT) standard.
    gem "jwt", "~> 2.5.0"
    # bcrypt() is a sophisticated and secure hash algorithm designed by The OpenBSD project for hashing passwords.
    gem "bcrypt", "~> 3.1.18"
    # jsonapi-rb is a ruby library for producing and consuming JSON API documents.
    gem "jsonapi-rails", "~> 0.4.1"

- I am using _redis-namespace_ to "wrap" Redis into the application namespace.
- I am using _Kredis_ for higher-level Redis data structures and initialize it from namespaced Redis.
- _jwt_ for JSON Web Token encoding/decoding.
- I am using _bcrypt_ for password_digest.
- And I am using jsonapi-rails for JSON API serializers.

## How it works

We have two main controllers: UsersController and AuthenticationController.
Routes:

    resources :users
    post 'auth/login', to: 'authentication#login'
    put 'auth/logout', to: 'authentication#logout'
    get 'auth/ping', to: 'authentication#ping'

In UsersController, you can create, edit, delete or index users. I am using BasicAuth to authorize access to these endpoints. Therefore, you need to set up environment variables JSON_API__MASTER_USERNAME and JSON_API__MASTER_SECRET and use them with BasicAuth to access these endpoints. 

Besides _username_ and _password_, I added _role_ to the user because it might be helpful when implementing APIs and authorization systems for them using a gem like __pundit__. I save only password_digests into Redis (not clean passwords) encrypted with bcrypt.

To access auth/login, you must use the username and password in BasicAuth that you create in POST /users.
Authorized POST auth/login refreshes user's token (currently to 30 min) and returns JSON Web Token, an encrypted token saved in Redis. 
It means that API users don't know the token saved in Redis and will not be able to query it even if they get access to Redis.
API user can then use JSON Web Token received from auth/login to access other API. For test purposes, I created auth/ping, which returns code 200 OK if BearerToken in Authorization headers was set to correct JSON Web Token.

User tokens expire automatically by Redis every 30 min. So if API users want to get another token, they can POST auth/login again

# What I would add

- I would limit access to /users endpoints by IPs to add more security.
- I only tested my controllers using postman.co tools. I would add ruby tests too.

