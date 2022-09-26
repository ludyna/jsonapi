$redis = Redis::Namespace.new(
	Rails.application.class.name.to_s.split("::")[0].downcase, 
	:redis => Redis.new(url: ENV.fetch("REDIS_URL", "redis://127.0.0.1:6379/0"))
)