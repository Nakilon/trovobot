require "webmock"
WebMock.enable!

require "trovobot"
Async = nil
Sync = nil

require "minitest/mock"
require "minitest/autorun"
describe "" do

  def b _in, _out, sender_id = "owner"
    TrovoBot.stub :start, ->&b{
      _in.each do |_|
        b.({type: 0, content: _, sender_id: sender_id}, "owner")
      end
    } do load "main.rb" end
    assert_equal _out.map{ |_| [_, "owner"] }, TrovoBot::queue.size.times.map{ TrovoBot::queue.pop }
  end

  it "ping" do
    b ["ping"], ["pong"]
  end

  it "\\access quote get" do
    TrovoBot.stub :name_to_id, ->_{_} do
    TrovoBot.stub :admin_name, "admin" do
    TrovoBot.stub :channel_name, "owner" do
      b ["\\access quote"], ["'s current access level: 8_owner"], "owner"
      b ["\\access quote"], ["'s current access level: 9_admin"], "admin"
      b ["\\access quote"], ["'s current access level: 0_query"], "someone"
      b ["\\access quote owner"], ["owner's current access level: 8_owner"]
      b ["\\access quote admin"], ["admin's current access level: 9_admin"]
      b ["\\access quote someone"], ["someone's current access level: 0_query"]
    end
    end
    end
  end
  it "\\access quote set" do
    TrovoBot.stub :name_to_id, ->_{_} do
    TrovoBot.stub :admin_name, "admin" do
    TrovoBot.stub :channel_name, "owner" do
      File.write "db.yaml", YAML.dump({})
      b [
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
