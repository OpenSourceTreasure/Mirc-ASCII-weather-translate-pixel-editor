# irc-translate-bot
An irc translation bot using Google Translate, works for every language.

## Installation

First, clone this repository and cd into it:
```
git clone https://github.com/forerosantiago/irc-translate-bot && cd irc-translate-bot/
```

Install the dependencies:
```
npm install
```

Edit the `config.json` file:
```
{
    "nick": "Translator",
    "server": "irc.planetofnix.com"
}
```

Execute it:
```
node index.js
```

## Usage
Once the bot is running and connected to an irc server you can use it like this:

```
-es Text to be translated
```

The command is the iso code for the desired language, a list of all the iso language codes can be found [here](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes).


### Joining and leaving channels
You can make the bot join any channel you want using the irc `/invite` commmand, the bot will remember it and join again if it gets disconnected.

If you don't want the bot to be in your channel anymore you can simply use the `/kick` command with it, it will forget your channel and won't come back unless reinvited.
