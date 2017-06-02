require 'sidekiq/web'

run Rack::URLMap.new('/sidekiq' => Sidekiq::Web)
