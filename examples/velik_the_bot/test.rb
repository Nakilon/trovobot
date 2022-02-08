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
    } do load "main.rb" end
    assert_equal [[_out, "owner"]], TrovoBot::queue.size.times.map{ TrovoBot::queue.pop }
  end

  it "ping" do
    a "pong", "ping"
  end

  it "\\access quote get" do
    TrovoBot.stub :name_to_id, ->_{_} do
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
  it "\\access quote set" do
    b = lambda do |_in, _out|
      TrovoBot.stub :start, ->&b{
        _in.each do |_|
          b.({type: 0, content: _, sender_id: "owner"}, "owner")
        end
      } do
        File.write "db.yaml", YAML.dump({})
        load "main.rb"
      end
      assert_equal _out.map{ |_| [_, "owner"] }, TrovoBot::queue.size.times.map{ TrovoBot::queue.pop }
    end
    TrovoBot.stub :name_to_id, ->_{_} do
    TrovoBot.stub :admin_name, "admin" do
    TrovoBot.stub :channel_name, "owner" do
      b.call [
        "\\access quote someone",
        "\\access quote someone +",
        "\\access quote someone",
        "\\access quote someone -",
        "\\access quote someone",
      ], [
        "someone's current access level: 0_query",
        "someone's new access level: 1_add",
        "someone's current access level: 1_add",
        "someone's new access level: 0_query",
        "someone's current access level: 0_query",
      ]
    end
    end
    end
  end

end
