# ARGV: <channel name> <code>

require "trovobot"
channel_id = TrovoBot::name_to_id ARGV[0]
Common::cache_text "#{channel_id}.channel.json" do
  NetHTTPUtils.request_data "https://open-api.trovo.live/openplatform/exchangetoken", :POST, :json, header: {
    "Client-ID" => File.read("clientid"),
  }, form: {
    client_secret: File.read("clientsecret"),
    grant_type: "authorization_code",
    code: Common::cache_text("#{channel_id}.channel_code"){ ARGV[1] || fail },
    redirect_uri: "https://trovo.live/",
  }
end
