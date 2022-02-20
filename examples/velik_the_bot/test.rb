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

  # TODO: test cmd aliases

  describe "\\access and \\quote" do
    around do |test|
      TrovoBot.stub :name_to_id, ->_{_} do
      TrovoBot.stub :admin_name, "admin" do
      TrovoBot.stub :channel_name, "owner" do
        File.write "db.yaml", YAML.dump({})
        test.call
      end
      end
      end
    end

    # TODO: maybe not File.write the db but File.delete?

    [
      ["quote", "query", "add"],
      ["bet", "participate", "initiate"],
    ].each do |cmd, l0, l1|
      it "\\access #{cmd} get" do
        b [["\\access #{cmd}", "'s current \\#{cmd} access level: 8 (owner)"]]
        b [["\\access #{cmd}", "'s current \\#{cmd} access level: 9 (admin)"]], "admin"
        b [["\\access #{cmd}", "'s current \\#{cmd} access level: 0 (#{l0})"]], "someone"
        [nil, "admin", "someone"].each do |who|
          b [
            ["\\access #{cmd} owner", "owner's current \\#{cmd} access level: 8 (owner)"],
            ["\\access #{cmd} admin", "admin's current \\#{cmd} access level: 9 (admin)"],
            ["\\access #{cmd} someone", "someone's current \\#{cmd} access level: 0 (#{l0})"],
          ], *who
        end
      end
      it "\\access #{cmd} set" do
        b [
          ["\\access #{cmd} someone", "someone's current \\#{cmd} access level: 0 (#{l0})"],
          ["\\access #{cmd} someone +", "someone's new \\#{cmd} access level: 1 (#{l1})"],
          ["\\access #{cmd} someone", "someone's current \\#{cmd} access level: 1 (#{l1})"],
          ["\\access #{cmd} someone -", "someone's new \\#{cmd} access level: 0 (#{l0})"],
          ["\\access #{cmd} someone", "someone's current \\#{cmd} access level: 0 (#{l0})"],
        ]
        b [
          ["\\access #{cmd} someone", "someone's current \\#{cmd} access level: 0 (#{l0})"],
          ["\\access #{cmd} someone +", "access denied"],
          ["\\access #{cmd} someone", "someone's current \\#{cmd} access level: 0 (#{l0})"],
          ["\\access #{cmd} someone -", "access denied"],
        ], "someone"
        b [
          ["\\access #{cmd} someone", "someone's current \\#{cmd} access level: 0 (#{l0})"],
          ["\\access #{cmd} someone +", "someone's new \\#{cmd} access level: 1 (#{l1})"],
          ["\\access #{cmd} someone", "someone's current \\#{cmd} access level: 1 (#{l1})"],
          ["\\access #{cmd} someone -", "someone's new \\#{cmd} access level: 0 (#{l0})"],
          ["\\access #{cmd} someone", "someone's current \\#{cmd} access level: 0 (#{l0})"],
          ["\\access #{cmd} someone +", "someone's new \\#{cmd} access level: 1 (#{l1})"],
        ], "admin"
        b [
          ["\\access #{cmd} someone -", "access denied"],
          ["\\access #{cmd}", "'s current \\#{cmd} access level: 1 (#{l1})"],
        ], "someone"
      end
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
      b [["\\access quote someone +", "someone's new \\quote access level: 1 (add)"]]
      b [
        ["\\quote add hello world", "quote #4 added"],
        ["\\quote 4", "#4: hello world"],
        ["\\quote del 3", "access denied"],
        ["\\quote del 4", "quote #4 deleted"],
        ["\\quote 4", "quote #4 not found"],
        ["\\quote add hello world", "quote #5 added"],
      ], "someone"
      b [["\\access quote someone -", "someone's new \\quote access level: 0 (query)"]]
      b [
        ["\\quote add hello world", "access denied"],
        ["\\quote del 5", "access denied"],
      ], "someone"
      b [["\\quote del 5", "quote #5 deleted"]]
    end

    it "\\bet" do
      [nil, "admin"].each do |who|
        File.write "db.yaml", YAML.dump({})
        b [["\\bet points", " has 100 points for bets"]]
        b [["\\bet points", " has 100 points for bets"]], "admin"
        b [["\\bet points", " has 100 points for bets"]], "someone"
        [nil, "admin", "someone"].each do |who|
          b [
            ["\\bet points owner", "owner has 100 points for bets"],
            ["\\bet points admin", "admin has 100 points for bets"],
            ["\\bet points someone", "someone has 100 points for bets"],
          ], *who
        end
        b [["\\bet start will win? yes no", "access denied"]], "someone"
        b [
          ["yes", nil],
          ["\\bet freeze", "there is no betting at the moment"],
          ["\\bet finish yes", "there is no betting at the moment"],
          ["\\bet start will win?", nil],
          ["\\bet start will win yes no", nil],
          ["\\bet start will win? yes no", "will win? 'yes' or 'no'"],
          ["\\bet start will win? yes no", "there is ongoing betting"],
          ["yes 10", nil],
          ["yes 100", nil],
          ["\\bet freeze", "bets are made"],
          ["\\bet finish", nil],
          ["\\bet finish finish", "finish with 'yes' or 'no'"],
        ], *who
        b [["\\access bet someone +", "someone's new \\bet access level: 1 (initiate)"]]
        b [
          ["\\bet finish yes", ""],
          ["\\bet start will win? yes no", "will win? 'yes' or 'no'"],
        ], "someone"
      end
    end

    #   bet revert
    #   bet cancel = finish + revert

  end

end
