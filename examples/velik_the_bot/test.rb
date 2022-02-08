require "webmock"
WebMock.enable!

require "trovobot"
Async = nil

require "minitest/mock"
require "minitest/autorun"
describe "" do

  def a _in, _out
    TrovoBot.stub :start, ->&b{
      b.({type: 0, content: _in})
      assert_equal [[_out, nil]], TrovoBot::queue.size.times.map{ TrovoBot::queue.pop }
    } do load "main.rb" end
  end

  it "ping" do
    a "ping", "pong"
  end

  it "\\access quote" do
    a "\\access quote", "'s current access level: 8_owner"
  end

end
