require "webmock"
WebMock.enable!

require "trovobot"
Async = nil

require "minitest/mock"
require "minitest/autorun"
describe "" do
  it do
    TrovoBot.stub :start, (lambda do |&b|
      b.({type: 0, content: "ping"})
      assert_equal [["pong", nil]], TrovoBot::queue.size.times.map{ TrovoBot::queue.pop }
    end) do
      # ARGV[0] = ARGV[1] = ""
      load "main.rb"
    end
  end
end
