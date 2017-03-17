# sax robot

saxrobot/saxbot is a novelty IRC bot who counts user-set trigger words in
IRC channel messages and constructs a reply of user-set replies for each
instance of a trigger word in a message.

It's hard to word it nicely, so here's an example.

## Example:

Under the default configuration, saxrobot will trigger on 'sax', 'trumpet'
and 'snake', replying with '🎷', '🎺' and '🐍' respectively. Take a look at
this IRC log:

	<someuser> sax
	<somesaxbot> 🎷 
	<someuser> sax snake
	<somesaxbot> 🎷 🐍 
	<someuser> saxaphone woosaxsnakeSAXalright trumpetTRUMPET
	<somesaxbot> 🎷 🎷 🐍 🎷 🎺 🎺 

Simple eh.
