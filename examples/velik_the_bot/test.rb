require "webmock"
WebMock.enable!

require "trovobot"
Async = nil
Sync = nil

require "minitest/mock"
require "minitest/around/spec"
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

  describe "\\access and \\quote" do
    around do |test|
      TrovoBot.stub :name_to_id, ->_{_} do
      TrovoBot.stub :admin_name, "admin" do
      TrovoBot.stub :channel_name, "owner" do
        test.call
      end
      end
      end
    end

    # TODO: maybe not File.write the db but File.delete?

    it "\\access quote get" do
      b ["\\access quote"], ["'s current access level: 8_owner"]
      b ["\\access quote"], ["'s current access level: 9_admin"], "admin"
      b ["\\access quote"], ["'s current access level: 0_query"], "someone"
      b ["\\access quote owner"], ["owner's current access level: 8_owner"]
      b ["\\access quote admin"], ["admin's current access level: 9_admin"]
      b ["\\access quote someone"], ["someone's current access level: 0_query"]
    end
    it "\\access quote set" do
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
      b [
        "\\access quote someone",
        "\\access quote someone +",
        "\\access quote someone",
        "\\access quote someone -",
        "\\access quote someone",
      ], [
        "someone's current access level: 0_query",
        "access denied",
        "someone's current access level: 0_query",
        "access denied",
        "someone's current access level: 0_query",
      ], "someone"
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
      ], "admin"
    end

    it "\\quote" do
      [nil, "admin"].each do |who|
        File.write "db.yaml", YAML.dump({})
        b [
          "\\quote",
          "\\quote 0",
          "\\quote 1",
          "\\quote quote",
          "\\quote search hello",
          "\\quote add hello world",
          "\\quote",
          "\\quote 0",
          "\\quote 1",
          "\\quote 2",
          "\\quote quote",
          "\\quote search hello",
          "\\quote add hello world",
          "\\quote 2",
          "\\quote 3",
          "\\quote quote",
          "\\quote search hello",
          "\\quote del 0",
          "\\quote del hello",
          "\\quote del 1",
          "\\quote 1",
          "\\quote search hello",
          "\\quote add hello world",
        ], [
          "no quotes yet, go ahead and use '\\quote add <text>' to add some!",
          "quote #0 not found",
          "quote #1 not found",
          "nothing found",
          "quote #1 added",
          "#1: hello world",
          "quote #0 not found",
          "#1: hello world",
          "quote #2 not found",
          "#1: hello world",
          "quote #2 added",
          "#2: hello world",
          "quote #3 not found",
          "2 matches",
          "quote #0 not found",
          "quote #1 deleted",
          "quote #1 not found",
          "#2: hello world",
          "quote #3 added",
        ], *who
      end
      b [
        "\\quote 2",
        "\\quote add hello world",
        "\\quote 4",
        "\\quote del 3",
      ], [
        "#2: hello world",
        "access denied",
        "quote #4 not found",
        "access denied",
      ], "someone"
      b ["\\access quote someone +"], ["someone's new access level: 1_add"]
      b [
        "\\quote add hello world",
        "\\quote 4",
        "\\quote del 3",
        "\\quote del 4",
        "\\quote 4",
        "\\quote add hello world",
      ], [
        "quote #4 added",
        "#4: hello world",
        "access denied",
        "quote #4 deleted",
        "quote #4 not found",
        "quote #5 added",
      ], "someone"
      b ["\\access quote someone -"], ["someone's new access level: 0_query"]
      b [
        "\\quote add hello world",
        "\\quote del 5",
      ], [
        "access denied",
        "access denied",
      ], "someone"
      b ["\\quote del 5"], ["quote #5 deleted"]
    end

  end

end
