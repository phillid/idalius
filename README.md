# idalius

idalius started out as a novelty IRC bot. Its original functionality has now
been moved into an optional module, "titillate", while the remainder of the
bot's functionality is mostly configurable and extensible.

Gradually, what used to be the bot's core, `idalius.pl` is becoming more
and more of a shell/framework, with what used to be "core functionality" being
moved off to loadable modules. This is work is still in-progress.

## Plugins/Modules

idalius allows a lot of what is often considered a bot's standard functionality
to be swapped out, or disabled altogether. Below is a list of some common
plugins that you probably want to enable for your run-of-the-mill IRC bot.

### Recommended plugins

These plugins will give you a "base" bot that does nothing more than joining
(and staying joined to) channels, logging messages to stdout, allowing basic
puppeting.

* **Plugin::Admin** - Allows specific users to puppet the bot (kick, join, part
  set modes, say things to channels/people, etc.). Also allows runtime plugin
  loading/unloading.
* **Plugin::Autojoin** - Causes the bot to ask to join a preconfigured set of
  channels when first connecting to an IRC server.
* **Plugin::Log** - Logs IRC traffic and other events that the bot sees in the
  channels it joins, server announcements, notices etc.
* **Plugin::Rejoin** - This one only just makes it into the recommended list,
  since the behaviour this module enables can be viewed by some people as
  annoying. This plugin will cause your bot to automatically attempt to rejoin
  a channel if it is kicked from it.

### All Plugins

These are all plugins available in the standard distribution.

* **Plugin::Admin** - Puppeting, ignoring/unignoring users, setting of command prefix, killing the bot, loading/unloading of plugins.
* **Plugin::Antiflood** - Kicks users who send too many messages at once.
* **Plugin::Autojoin** - Joins a configured set of channels when connecting to a server.
* **Plugin::Convert** - Wraps and requires the GNU Units utility for unit conversion in-channel.
* **Plugin::Dad** - Jumps in on certain phrases in channels to tell crappy dad jokes.
* **Plugin::DevNull** - Adds commands to wrap and silence other commands.
* **Plugin::Echo** - Adds a simple echo command for anyone to use.
* **Plugin::Greet** - Triggers the bot to have a chance of greeting a channel as it joins, and other users as they join.
* **Plugin::Hmm** - Say some pensive words if a channel receives no activity for some time.
* **Plugin::Jinx** - Repeat messages in a channel if they are "on streak". E.g. say "lol" if it's been said twice in a row in a channel.
* **Plugin::Log** - Log a variety of bot and IRC events to stdout.
* **Plugin::Map** - Adds a functional mapping command, useful for running bot commands over varied of values.
* **Plugin::Men** - Sometimes respond to messages with "men" in them with "not just the men, but the women and children, too!". E.g. "Not just the comments, but the cowoments and cochildrents, too!"
* **Plugin::Natural** - Sometimes respond to messages in the channel, to make the bot seem vaguely more human.
* **Plugin::Ping** - Adds a ping command.
* **Plugin::Random** - Adds a shuffle and choose/random choice command.
* **Plugin::Rejoin** - Rejoin to channels the bot is kicked from.
* **Plugin::Source** - Adds some commands for displaying the upstream source locations for the bot.
* **Plugin::Thanks** - Adds some commands so the bot responds to being thanked directly.
* **Plugin::Timezone** - Adds a command to calculate the current time of day for various timezones or users.
* **Plugin::Titillate** - Auto-respond to configured parts of messages in channels.
* **Plugin::URL_Title** - Respond in-channel with a title for any URLs posted which point to HTML/SVG.
* **Plugin::Vote** - Adds commands for voting on topics.
