# idalius

idalius started out as a novelty IRC bot. Its original functionality has now
been moved into an optional module, "tittilate", while the remainder of the
bot's functionality is mostly configurable and extensible.

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
