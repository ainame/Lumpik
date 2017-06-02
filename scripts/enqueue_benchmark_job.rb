require 'securerandom'
require 'redis'

redis = Redis.new(host: "127.0.0.1", port: 6379)
redis.pipelined do |r|
  r.del("queue:default")
  100_000.times do |i|
    value = "{\"jid\": \"#{SecureRandom.uuid}\",\"class\":\"EchoWorker\",\"args\":[\"#{i}\"],\"retry\":1,\"queue\":\"default\",\"created_at\":#{Time.now.to_f},\"enqueued_at\":#{Time.now.to_f}}"
    r.lpush("queue:default", value)
  end

  r.del("queue:other")
  #50_000.times do |i|
  #  value = "{\"jid\": \"#{SecureRandom.uuid}\",\"class\":\"EchoWorker\",\"args\":[\"#{i}\"],\"retry\":1,\"queue\":\"other\"}"
  #  r.lpush("queue:other", value)
  #end
end
