# usage: bundle exec ruby main.rb <admin name> <channel name>

require "trovobot"

require "yaml/store"
db = YAML::Store.new "db.yaml"
get_level = lambda do |sender_id, channel_id|
  next "8_owner" if sender_id == channel_id
  next "9_admin" if sender_id == TrovoBot.name_to_id(TrovoBot.admin_name)
  db.transaction(true){ |tr| tr.fetch "access.quote.#{channel_id}.#{sender_id}", "0_query" }
end

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

        when /\A\\help\s+access(\s|\z)/
          TrovoBot::queue.push [
            "see own access level: \\access quote; "\
            "see someone's access level: \\access quote <nickname>; "\
            "add/remove ability to add new quotes (only for channel owner and bot admin): \\access quote <nickname> +/-",
            channel_id
          ]
        when /\A\\access\s+quote\z/
          TrovoBot::queue.push ["#{chat[:nick_name]}'s current access level: #{get_level[chat[:sender_id], channel_id]}", channel_id]
        when /\A\\access\s+quote\s+(\S+)\z/
          TrovoBot::queue.push ["#{$1}'s current access level: #{get_level[TrovoBot::name_to_id($1), channel_id]}", channel_id]
        when /\A\\access\s+quote\s+(\S+)\s+\+\z/
          name = $1
          next TrovoBot::queue.push ["access denied", channel_id] unless "8" <= get_level[chat[:sender_id], channel_id]
          id = TrovoBot::name_to_id name
          db.transaction{ |tr| tr["access.quote.#{channel_id}.#{id}"] = "1_add" }
          TrovoBot::queue.push ["#{name}'s new access level: 1_add", channel_id]
        when /\A\\access\s+quote\s+(\S+)\s+\-\z/
          name = $1
          next TrovoBot::queue.push ["access denied", channel_id] unless "8" <= get_level[chat[:sender_id], channel_id]
          id = TrovoBot::name_to_id name
          db.transaction{ |tr| tr["access.quote.#{channel_id}.#{id}"] = "0_query" }
          TrovoBot::queue.push ["#{name}'s new access level: 0_query", channel_id]

        when /\A\\help\s+quote(\s|\z)/
          TrovoBot::queue.push [
            "show random quote: \\quote; "\
            "show specific quote: \\quote <number>; "\
            "search a word: \\quote search <word>; "\
            "add quote: \\quote add <text>; "\
            "delete quote (only for quote author, channel owner, and bot admin): \\quote del <number>",
            channel_id
          ]
        when /\A\\q(?:uote)?\z/
          i, quote = db.transaction(true) do |tr|
            tr.roots.grep(/\Aquote\.#{channel_id}\./).map{ |id| [id.split(?.).last, tr[id]] }
          end.select(&:last).sample
          TrovoBot::queue.push [quote ? "##{i}: #{quote[:text]}" : "no quotes yet, go ahead and use '\\quote add <text>' to add some!", channel_id]
        when /\A\\q(?:uote)?\s+search\s+(\S.*?)\s*\z/
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
        when /\A\\q(?:uote)?\s+(\d+)\z/
          i = $1
          quote = db.transaction(true){ |tr| tr["quote.#{channel_id}.#{i}"] }
          TrovoBot::queue.push [quote ? "##{i}: #{quote[:text]}" : "quote ##{i} not found", channel_id]
        when /\A\\q(?:uote)?\s+add\s+(\S.*?)\s*\z/
          text = $1
          next TrovoBot::queue.push ["access denied", channel_id] unless "1" <= get_level[chat[:sender_id], channel_id]
          i = db.transaction do |tr|
            ((tr.roots.grep(/\Aquote\.#{channel_id}\./).map{ |_| _.split(?.).last.to_i }.max || 0) + 1).tap do |max|
              tr["quote.#{channel_id}.#{max}"] = {author: chat[:sender_id], text: text}
            end
          end
          TrovoBot::queue.push ["quote ##{i} added", channel_id]
        when /\A\\q(?:uote)?\s+del\s+(\d+)\z/
          i = $1
          next TrovoBot::queue.push ["access denied", channel_id] unless "1" <= get_level[chat[:sender_id], channel_id]
          result = db.transaction do |tr|
            next "quote ##{i} not found" unless quote = tr[root = "quote.#{channel_id}.#{i}"]
            next "access denied" unless chat[:sender_id] == quote[:author] || "8" <= get_level[chat[:sender_id], channel_id]
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

        when /\A\\help(\s|\z)/
          TrovoBot::queue.push [
            "for help: \\help <command>; "\
            "available commands: help, access, quote",
            channel_id
          ]

        end
      end

end
