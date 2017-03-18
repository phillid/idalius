# idalius

idalius is a novelty IRC bot who counts user-set trigger words in
IRC channel messages and constructs a reply of user-set replies for each
instance of a trigger word in a message.

It's hard to word it nicely, so here's an example.

## Example:

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
