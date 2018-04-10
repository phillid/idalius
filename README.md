# idalius

idalius started out as a novelty IRC bot. Its original functionality has now
been moved into an optional module, "tittilate", while the remainder of the
bot's functionality is mostly configurable and extensible.

## Commands

Arbitrary commands can be registered by any module. Commands (currently
separate from admin commands) are issued in-channel, prefixed with the string
configured in the `bot.conf` parameter `prefix`. This is `%` by default, and
this default will be used in this README.

## Module: URL Title

idalius can pick a URL out of any channel message and respond in-channel with
the title of the link, followed by the hostname so you know roughly what link
the title is for.

	<phillid> Testing the URL title thingy https://sighup.nz/ and presuming it works
	<idalius> Ahoy-hoy ☃ SIGHUP (sighup.nz)


## Module: Tittilate

The tittilate module is one which will ask idalius to check all channel
messages for special keywords, and for each message containing some of those
keywords, respond with a message with as many user-set responses to those
keywords, in order. It's kind of hard to get your head around with plain
words, so I'll give an example.

Under the default configuration, idalius will trigger on 'sax', 'trumpet'
and 'snake', replying with '🎷', '🎺' and '🐍' respectively. Take a look at
this IRC log:

	<someuser> sax
	<somebot> 🎷 
	<someuser> sax snake
	<somebot> 🎷 🐍 
	<someuser> saxaphone woosaxsnakeSAXalright trumpetTRUMPET
	<somebot> 🎷 🎷 🐍 🎷 🎺 🎺 

Simple eh.

## Module: Antiflood

This module will kick someone who send more than 5 messages in 11 seconds on
a channel. It's on the to-do list to make these parameters configurable.

## Module: Echo

This module adds a command to echo strings on-channel. Example:

	<someone> %echo woo stuff
	<somebot> woo stuff

## Module: Map

This module allows simplistic mapping of a function across a list of arguments.
At the moment, array syntax is just prototypical, and uses regex to split on
commas. Thus, nesting of , within arguments is not yet possible. Examples:

	<someone> %map echo foo,bar, foobar
	<somebot> [foo, bar, foobar]

## Module: Timezone

This module allows timezones to be associated with words (intended for use
with nicks) so that the command `%time foo` will return the current time,
adjusted for the timezone associated with `foo`. Example:

	<person1> %time person1
	<somebot> person1: person1's clock reads 2018-04-10T06:39:44

## Admin commands

idalius also supports some basic administration commands. These should be sent
in a private message to the bot by someone with a hostmask configured to be an
administrator's hostmask.

At the moment these commands comprise:

### Nick change

	nick fooeybot

Attempt to change the bot's IRC nick name to fooeybot.

### Part/leave from channels

	part #channel
	part #channel some part message
	part #channel #anotherone
	part #channel #anotherone witty part message here

Leave/part from one or more channels, giving an optional part message. This
part message will be used for the parts sent to each channel specified.

### Join channels

	join #channel
	join #channel #someotherchannel #omganotherchannel #holymoly

Join one or more channels

### Say something to a channel or person

	say nick I'm here for you, Jack
	say #channel Hey hi hello howdy

Tell a person or a channel something, perferably something useful. Useful for
puppeting if you are not on a channel, or you could talk to yourself through
an idalius bot if you get lonely. Additionally, it might be useful for your
idalius to contact services like nickserv, memoserv, chanserv etc.

### Perform a CTCP action to a channel or person

	action nick slaps you with a fish
	action #channel stares down everyone in the room

Not really useful apart from having a laugh in a channel. Really not sure why
I added this except for a lame gag or two. Worth it.

### Set channel/user modes

	mode #channel +v someone
	mode #channel +vo someone opguy
	mode #channel +n
	mode #channel +l 5

So on and so forth. What comes after "mode" is sent verbatim to the IRC client
idalius wraps, which (as far as I know) sends it verbatim to the server. So
you're really down to whatever the IRC server you're on will understand.

### Kick someone from a channel

	kick #channel badPerson
	kick #channel badPerson You've been very naughty!

Kicks badPerson from #channel, and optionally takes your specified kick reason
to relay with the kick. If you do not specify a kick reason, then idalius will
use a default message "Requested by <yourNameHere!>".

### Reconnect

	reconnect
	reconnect witty message

Code isn't bug-free, and idalius is far from it. If you manage to break your
idalius beyond repair, you might want to look at asking it remotely to
disconnect from the IRC server and connect back to it again to start from a
clean slate.

Your idalius will ask the IRC server to use a witty quit message if you
specify one, otherwise it will fall back on the default quit message specified
in the config file (quit_msg)
