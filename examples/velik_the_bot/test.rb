require "webmock"
WebMock.enable!

require "trovobot"
Async = nil
Sync = nil

require "minitest/mock"
require "minitest/around/spec"
require "minitest/autorun"
describe "" do

  def b in_out, sender_id = "owner"
    _in, _out = in_out.transpose.map(&:compact)
    TrovoBot.stub :start, ->&b{
      _in.each do |_|
        b.({type: 0, content: _, sender_id: sender_id}, "owner")
      end
    } do load "main.rb" end
    assert_equal _out.map{ |_| [_, "owner"] }, TrovoBot::queue.size.times.map{ TrovoBot::queue.pop }
  end

  it "ping" do
    b [["ping", "pong"]]
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
      b [["\\access quote", "'s current access level: 8_owner"]]
      b [["\\access quote", "'s current access level: 9_admin"]], "admin"
      b [["\\access quote", "'s current access level: 0_query"]], "someone"
      [nil, "admin", "someone"].each do |who|
        b [
          ["\\access quote owner", "owner's current access level: 8_owner"],
          ["\\access quote admin", "admin's current access level: 9_admin"],
          ["\\access quote someone", "someone's current access level: 0_query"],
        ], *who
      end
    end
    it "\\access quote set" do
      File.write "db.yaml", YAML.dump({})
      b [
        ["\\access quote someone", "someone's current access level: 0_query"],
        ["\\access quote someone +", "someone's new access level: 1_add"],
        ["\\access quote someone", "someone's current access level: 1_add"],
        ["\\access quote someone -", "someone's new access level: 0_query"],
        ["\\access quote someone", "someone's current access level: 0_query"],
      ]
      b [
        ["\\access quote someone", "someone's current access level: 0_query"],
        ["\\access quote someone +", "access denied"],
        ["\\access quote someone", "someone's current access level: 0_query"],
        ["\\access quote someone -", "access denied"],
      ], "someone"
      b [
        ["\\access quote someone", "someone's current access level: 0_query"],
        ["\\access quote someone +", "someone's new access level: 1_add"],
        ["\\access quote someone", "someone's current access level: 1_add"],
        ["\\access quote someone -", "someone's new access level: 0_query"],
        ["\\access quote someone", "someone's current access level: 0_query"],
        ["\\access quote someone +", "someone's new access level: 1_add"],
      ], "admin"
      b [
        ["\\access quote someone -", "access denied"],
        ["\\access quote", "'s current access level: 1_add"],
      ], "someone"
    end

    it "\\quote" do
      [nil, "admin"].each do |who|
        File.write "db.yaml", YAML.dump({})
        b [
          ["\\quote", "no quotes yet, go ahead and use '\\quote add <text>' to add some!"],
          ["\\quote 0", "quote #0 not found"],
          ["\\quote 1", "quote #1 not found"],
          ["\\quote quote", nil],
          ["\\quote search hello", "nothing found"],
          ["\\quote add hello world", "quote #1 added"],
          ["\\quote", "#1: hello world"],
          ["\\quote 0", "quote #0 not found"],
          ["\\quote 1", "#1: hello world"],
          ["\\quote 2", "quote #2 not found"],
          ["\\quote search hello", "#1: hello world"],
          ["\\quote add hello world", "quote #2 added"],
          ["\\quote 2", "#2: hello world"],
          ["\\quote 3", "quote #3 not found"],
          ["\\quote search hello", "2 matches"],
          ["\\quote del 0", "quote #0 not found"],
          ["\\quote del hello", nil],
          ["\\quote del 1", "quote #1 deleted"],
          ["\\quote 1", "quote #1 not found"],
          ["\\quote search hello", "#2: hello world"],
          ["\\quote add hello world", "quote #3 added"],
        ], *who
      end
      b [
        ["\\quote 2", "#2: hello world"],
        ["\\quote add hello world", "access denied"],
        ["\\quote 4", "quote #4 not found"],
        ["\\quote del 3", "access denied"],
      ], "someone"
      b [["\\access quote someone +", "someone's new access level: 1_add"]]
      b [
        ["\\quote add hello world", "quote #4 added"],
        ["\\quote 4", "#4: hello world"],
        ["\\quote del 3", "access denied"],
        ["\\quote del 4", "quote #4 deleted"],
        ["\\quote 4", "quote #4 not found"],
        ["\\quote add hello world", "quote #5 added"],
      ], "someone"
      b [["\\access quote someone -", "someone's new access level: 0_query"]]
      b [
        ["\\quote add hello world", "access denied"],
        ["\\quote del 5", "access denied"],
      ], "someone"
      b [["\\quote del 5", "quote #5 deleted"]]
    end

    # it "\\bet" do
    #   bet start
    #   bet finish
    #   bet yes
    #   bet no
    #   bet freeze
    #   bet revert
    #   bet cancel = finish + revert
    # end

  end

end
