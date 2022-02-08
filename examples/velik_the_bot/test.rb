require "webmock"
WebMock.enable!

require "trovobot"
Async = nil
Sync = nil

require "minitest/mock"
require "minitest/autorun"
describe "" do

  def a _out, _in, sender_id = nil
    TrovoBot.stub :start, ->&b{
      b.({type: 0, content: _in, sender_id: sender_id}, "owner")
      assert_equal [[_out, "owner"]], TrovoBot::queue.size.times.map{ TrovoBot::queue.pop }
    } do load "main.rb" end
  end

  it "ping" do
    a "pong", "ping"
  end

  it "\\access quote" do
    TrovoBot.stub :name_to_id, ->_{ _ } do
    TrovoBot.stub :admin_name, "admin" do
    TrovoBot.stub :channel_name, "owner" do
      a "'s current access level: 8_owner", "\\access quote", "owner"
      a "'s current access level: 9_admin", "\\access quote", "admin"
      a "'s current access level: 0_query", "\\access quote", "someone"
      a "owner's current access level: 8_owner", "\\access quote owner"
      a "admin's current access level: 9_admin", "\\access quote admin"
      a "someone's current access level: 0_query", "\\access quote someone"
    end
    end
    end
  end

end
