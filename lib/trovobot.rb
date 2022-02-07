module TrovoBot
  require_relative "trovobot/common"

  require "async"
  require "async/semaphore"
  require "nethttputils"
  require "pp"

  SEMAPHORE_TIME = Async::Semaphore.new
  private_constant :SEMAPHORE_TIME
  SEMAPHORE_NETHTTP = Async::Semaphore.new 5
  @prev = Time.now
  def self.access_token
    JSON.load( ( Common::cache_text "tokens.json" do
      NetHTTPUtils.request_data "https://open-api.trovo.live/openplatform/exchangetoken", :POST, :json, header: {
        "Client-ID" => File.read("clientid"),
      }, form: {
        client_secret: File.read("clientsecret"),
        grant_type: "authorization_code",
        code: File.read("auth_code"),
        redirect_uri: "https://trovo.live/",
      }
    end ) ).fetch("access_token")
  end
  def self.request mtd, form = {}
    Sync do
      sleep SEMAPHORE_TIME.async{ [@prev + 0.1 - Time.now, 0].max.tap{ @prev = Time.now } }.wait
      JSON.load( SEMAPHORE_NETHTTP.async do
        NetHTTPUtils.request_data "https://open-api.trovo.live/openplatform/#{mtd}", :POST, :json, header: {
          "Client-ID" => File.read("clientid"),
          "Authorization" => "OAuth #{access_token}",
        }, form: form
      rescue NetHTTPUtils::Error => e
        p e.body
        case e.code
        when 401
          fail unless 11714 == JSON.load(e.body).fetch("status")
          Common::cache_text "tokens.json", true do
            NetHTTPUtils.request_data "https://open-api.trovo.live/openplatform/refreshtoken", :POST, :json, header: {
              "Client-ID" => File.read("clientid"),
            }, form: {
              client_secret: File.read("clientsecret"),
              grant_type: "refresh_token",
              refresh_token: JSON.load(File.read"tokens.json").fetch("refresh_token"),
            }
          end
          sleep 1   # TODO: remove?
          retry
        when 400
          fail unless 20000 == JSON.load(e.body).fetch("status")
          pp [mtd, form]
          raise
        end
      end.wait )
    end
  end
  def self.name_to_id name
    request("getusers", {user: [name || fail]})["users"].map{ |_| _["channel_id"] }[0].to_i
  end

  class << self
    attr_accessor :queue
  end
  self.queue = Queue.new
  Thread.new do
    loop do
      content, channel_id = queue.pop
      fail unless channel_id  # omitting (for sending to own channel) isn't implemented yet
      pp TrovoBot::request "chat/send", {content: content, channel_id: channel_id}
      sleep 1
    end
  end.abort_on_exception = true

  def self.start
    puts "admin -- #{ARGV[0]}"
    puts "channel -- #{ARGV[1]}"
    require "async/websocket/client"
    require "async/http/endpoint"
    Async do |task|
      puts "debug: Async"
      channel_id = name_to_id ARGV[1]
      chat_token = JSON.load( SEMAPHORE_NETHTTP.async do
        NetHTTPUtils.request_data "https://open-api.trovo.live/openplatform/chat/channel-token/#{channel_id}", header: {
          "Accept" => "application/json",
          "Client-ID" => File.read("clientid"),
        }
      end.wait )["token"]
      loop do
        puts "debug: loop"
        Async::WebSocket::Client.connect(Async::HTTP::Endpoint.parse "wss://open-chat.trovo.live/chat", alpn_protocols: Async::HTTP::Protocol::HTTP11.names) do |connection|
          puts "debug: connection"
          ping_task = task.async do
            loop do
              sleep 30
              connection.write( {type: "PING", nonce: ""} )
              connection.flush
            end
          end
          connection.write( {type: "AUTH", nonce: "", data: {token: chat_token}} )
          # TODO: wrap the file in a semaphore
          require "fileutils"
          FileUtils.touch "processed.jsonl" unless File.exist? "processed.jsonl"
          to_skip = File.read("processed.jsonl").split("\n")
          # trovo may send the same message but with slightly different attributes, such as avatar, so we store only ids
          while msg = connection.read
            # outdated?
            #   for efficiency if I start processing then I immediately stop skipping,
            #   so I don't process until it's type="CHAT" with new id
            # for now we only yield and track CHATs
            # next if msg.fetch(:type) == "PONG"
            next unless msg[:type] == "CHAT"
            new_msgs = msg[:data].fetch(:chats, []).reject{ |_| (to_skip || []).include? _.fetch :message_id }
            next if new_msgs.empty?
            to_skip = nil
            puts "< #{Time.now} #{Base64.strict_encode64 msg.to_s}"
            puts msg.pretty_inspect.gsub(/^/, "< ")
            new_msgs.each do |msg|
              yield msg, channel_id
            rescue
              puts $!.full_message
              TrovoBot::queue.push ["error at #{ARGV[1]}: #{$!}, #{$!.backtrace.first}", name_to_id(ARGV[0])]
            else
              File.open("processed.jsonl", "a"){ |_| _.puts msg.fetch :message_id }
            end
          end
        ensure
          ping_task&.stop
        end
      rescue Async::WebSocket::ProtocolError, OpenSSL::SSL::SSLError
        p $!
        sleep 5
        retry
      end
    end # we wanted to rescue Async::* errors to retry this but it appeared to also throw other kinds of exceptions so we just loop
  end
end
