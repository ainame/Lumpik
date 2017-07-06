require  'sidekiq'

class EchoWorker
  include Sidekiq::Worker

  def perform(message)
    puts(message)
  end
end

EchoWorker.perform_in(Time.now+10, "hello")
EchoWorker.perform_in(Time.now+60, "hello")
EchoWorker.perform_in(Time.now+100, "hello")
EchoWorker.perform_in(Time.now+120, "hello")
EchoWorker.perform_in(Time.now+180, "hello")
EchoWorker.perform_in(Time.now+180, "hello")
EchoWorker.perform_in(Time.now+600, "hello")
