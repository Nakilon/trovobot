# Trovo Live API library (bot)

## What

This is going to be the first Ruby gem for Trovo Live. It's my first Async gem experience so it might be a mess.

I use it for my chat bot https://trovo.live/velik_the_bot -- see the `examples` folder.

## How

There should be `clientid` and `clientsecret` files in working directory. Login as a bot and visiting https://open.trovo.live/page/login.html?client_id=...&response_type=code&scope=send_to_my_channel+chat_send_self+chat_connect&redirect_uri=https://trovo.live/ (or other scores, see Trovo API docs) and save the obtained code as the `auth_code` file. Delete the `tokens.json` if you updated the auth code.

If you not only consume the API but also make a bot that should write to someone's channel chat the channel owner should visit the https://open.trovo.live/page/login.html?client_id=...&response_type=code&scope=send_to_my_channel&redirect_uri=https://trovo.live/ and give you the auth code. You need it to run the `examples/velik_the_bot/channel_access.rb` script once as `ruby channel_access.rb <channel name> <code>` to generate the `....channel.json`, `....channel_code`. The channel owner should see the application to appear in his https://trovo.live/settings/account.

When using the bot functionality (`#start`) the `ARGV[0]` and `ARGV[1]` should be the admin and target channel names respectively.

The file `processed.jsonl` (needed to skip the processed chat messages) isn't rotating currently so you might want to cut it sometimes manually before it become a bottleneck.

## TODO

* neat logging
