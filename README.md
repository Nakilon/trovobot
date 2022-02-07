# Trovo Live API client + chat bot

## What

This is going to be the first Ruby gem for Trovo Live. It's my first Async gem experience so it ~~might be~~ is a mess.

I use it for my chat bot https://trovo.live/velik_the_bot -- see the `examples` folder.

## How

There should be `clientid` and `clientsecret` files in the working directory. Login as a bot, visit the https://open.trovo.live/page/login.html?client_id=...&response_type=code&scope=send_to_my_channel+chat_send_self+chat_connect&redirect_uri=https://trovo.live/ (or other scopes, see Trovo API docs) and save the obtained code as the `auth_code` file. Delete the `tokens.json` when updating the auth code.

In case you need not only API but also a bot to write to someone's channel chat then the channel owner should visit the https://open.trovo.live/page/login.html?client_id=...&response_type=code&scope=send_to_my_channel&redirect_uri=https://trovo.live/ and give you the obtained auth code. You pass it to the following script `ruby channel_access.rb <channel name> <code>` to generate the `....channel.json` and `....channel_code`. The channel owner will now see the application to appear in his https://trovo.live/settings/account.

When using the bot functionality (`#start`) the `ARGV[0]` and `ARGV[1]` should be the admin and target channel names respectively.

The file `processed.jsonl` (for keeping track of the next message to process) isn't rotating currently so you might want to cut it sometimes manually to avoid the bottleneck.

## TODO

* neat logging
