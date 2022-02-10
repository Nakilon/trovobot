# usage: bundle exec ruby main.rb <admin name> <channel name>

require "trovobot"

require "yaml/store"
db = YAML::Store.new "db.yaml"

resolve = lambda do |cmd|
  {
    "q"=>"quote", "quote"=>"quote", "цитата"=>"quote",
    "b"=>"bet", "bet"=>"bet", "ставка"=>"bet",
  }.fetch cmd
end
get_level = lambda do |sender_id, channel_id, cmd, tr = nil|
  next "8 (owner)" if sender_id == channel_id
  next "9 (admin)" if sender_id == TrovoBot.name_to_id(TrovoBot.admin_name)
  cmd = resolve[cmd]
  level = if tr
                               tr.fetch "access.#{cmd}.#{channel_id}.#{sender_id}", 0
  else
    db.transaction(true){ |tr| tr.fetch "access.#{cmd}.#{channel_id}.#{sender_id}", 0 }
  end
  "#{level} (#{{
    "quote" => %w{ query add },
    "bet" => %w{ participate initiate },
  }.fetch(cmd).fetch(level)})"
end

re_help = "(?:\\?|help|хелп|помощь|справка)"
re_access = "(?:a|access|доступ|права)"
re_quote = "(?:q|quote|цитата)"
re_bet = "(?:b|bet|ставка)"

TrovoBot.start do |chat, channel_id|   # this is designed for a multichannel bot it's yet a singleton
  # case msg[:type]
  # when "CHAT"
  #   msg[:data][:chats].each do |chat|

      case chat[:type]
      when 0
        next if "velik_the_bot" == chat[:nick_name]
        next TrovoBot::queue.push [chat[:content].tr("iI", "oO"), channel_id] if "ping" == chat[:content].downcase
        next TrovoBot::queue.push [chat[:content].tr("иИ", "оO"), channel_id] if "пинг" == chat[:content].downcase
        case chat[:content].strip

        when /\A\\#{re_help}\s+#{re_access}(\s|\z)/
          TrovoBot::queue.push [
            "see own access level: \\access {quote,bet}; "\
            "see someone's access level: \\access {quote,bet} <nickname>; "\
            "add/remove ability to add new quotes or initiate bets (only for channel owner and bot admin): \\access {quote,bet} <nickname> +/-",
            channel_id
          ]
        when /\A\\#{re_access}\s+(#{re_quote}|#{re_bet})\z/
          TrovoBot::queue.push ["#{chat[:nick_name]}'s current \\#{$1} access level: #{get_level[chat[:sender_id], channel_id, $1]}", channel_id]
        when /\A\\#{re_access}\s+(#{re_quote}|#{re_bet})\s+(\S+)\z/
          TrovoBot::queue.push ["#{$2}'s current \\#{$1} access level: #{get_level[TrovoBot::name_to_id($2), channel_id, $1]}", channel_id]
        when /\A\\#{re_access}\s+(#{re_quote}|#{re_bet})\s+(\S+)\s+([+-])\z/
          cmd, name, dir = $1, $2, $3
          next TrovoBot::queue.push ["access denied", channel_id] unless "8" <= get_level[chat[:sender_id], channel_id, cmd]
          id = TrovoBot::name_to_id name
          db.transaction{ |tr| tr["access.#{resolve[cmd]}.#{channel_id}.#{id}"] = dir == ?+ ? 1 : 0 }
          TrovoBot::queue.push ["#{name}'s new \\#{$1} access level: #{get_level[id, channel_id, cmd]}", channel_id]

        when /\A\\#{re_help}\s+#{re_quote}(\s|\z)/
          TrovoBot::queue.push [
            "show random quote: \\quote; "\
            "show specific quote: \\quote <number>; "\
            "search a word: \\quote search <word>; "\
            "add quote: \\quote add <text>; "\
            "delete quote (only for quote author, channel owner, and bot admin): \\quote del <number>",
            channel_id
          ]
        when /\A\\#{re_quote}\z/
          i, quote = db.transaction(true) do |tr|
            tr.roots.grep(/\Aquote\.#{channel_id}\./).map{ |id| [id.split(?.).last, tr[id]] }
          end.select(&:last).sample
          TrovoBot::queue.push [quote ? "##{i}: #{quote[:text]}" : "no quotes yet, go ahead and use '\\quote add <text>' to add some!", channel_id]
        when /\A\\#{re_quote}\s+search\s+(\S.*?)\s*\z/
          text = $1
          found = db.transaction(true) do |tr|
            tr.roots.grep(/\Aquote\.#{channel_id}\./).map{ |id| [id.split(?.).last, tr[id]] }
          end.select(&:last).select{ |i, q| q[:text][text] }
          TrovoBot::queue.push [
            case found.size
            when 0 ; "nothing found"
            when 1 ; "##{found[0][0]}: #{found[0][1][:text]}"
            else ; "#{found.size} matches"
            end,
            channel_id
          ]
        when /\A\\#{re_quote}\s+(\d+)\z/
          i = $1
          quote = db.transaction(true){ |tr| tr["quote.#{channel_id}.#{i}"] }
          TrovoBot::queue.push [quote ? "##{i}: #{quote[:text]}" : "quote ##{i} not found", channel_id]
        when /\A\\#{re_quote}\s+add\s+(\S.*?)\s*\z/
          text = $1
          next TrovoBot::queue.push ["access denied", channel_id] unless "1" <= get_level[chat[:sender_id], channel_id, "quote"]
          i = db.transaction do |tr|
            ((tr.roots.grep(/\Aquote\.#{channel_id}\./).map{ |_| _.split(?.).last.to_i }.max || 0) + 1).tap do |max|
              tr["quote.#{channel_id}.#{max}"] = {author: chat[:sender_id], text: text}
            end
          end
          TrovoBot::queue.push ["quote ##{i} added", channel_id]
        when /\A\\#{re_quote}\s+del\s+(\d+)\z/
          i = $1
          next TrovoBot::queue.push ["access denied", channel_id] unless "1" <= get_level[chat[:sender_id], channel_id, "quote"]
          result = db.transaction do |tr|
            next "quote ##{i} not found" unless quote = tr[root = "quote.#{channel_id}.#{i}"]
            next "access denied" unless chat[:sender_id] == quote[:author] || "8" <= get_level[chat[:sender_id], channel_id, "quote", tr]
            tr[root] = nil  # the number should be reserved forever
            "quote ##{i} deleted"
          end
          TrovoBot::queue.push [result, channel_id]

        # bet start
        # bet finish
        # bet yes
        # bet no
        # bet freeze
        # bet revert
        # bet cancel = finish + revert

        when /\A\\#{re_help}(\s|\z)/
          TrovoBot::queue.push [
            "for help: \\help <command>; "\
            "available commands: help, access, quote",
            channel_id
          ]

        end
      end

end
