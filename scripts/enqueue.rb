require 'sidekiq'
require 'pry'

class EchoWorker
  include Sidekiq::Worker

  sidekiq_options(queue: 'default', retry: 5)

  def perform(message)
    puts(message)
  end
end

class ComplexWorker
  include Sidekiq::Worker

  sidekiq_options(queue: 'complex', retry: 5)

  def perform(user_id, comment, data)
    puts("user_id:#{user_id}, comment:#{comment}, data:#{data}")
  end
end

binding.pry
